# desert_generator.gd

@tool
extends Node3D

## Proprietà del Generatore
const CHUNK_SIZE = 32 # Dimensione di un blocco (in vertici)
const CHUNK_AREA = 3 # Raggio di blocchi visibili (3 = 3x3 blocchi attorno al centro)
const VERTEX_SCALE = 2.0 # Spaziatura tra i vertici per la scala visiva
const HEIGHT_SCALE = 15.0 # Altezza massima delle dune
const SEED = 1234 # Seme per il rumore, per risultati ripetibili

## Dizionario per tenere traccia dei blocchi generati
var generated_chunks: Dictionary = {}

## Nodo Parent per i blocchi
@onready var chunks_parent = $ChunksParent

## Risorsa Rumore
var noise: FastNoiseLite = FastNoiseLite.new()

@export var player: Node3D


# --- Funzioni di Inizializzazione ---

func _ready():
	if Engine.is_editor_hint():
		return
		
	# Configura il Rumore Simplex
	noise.seed = SEED
	noise.frequency = 0.025 # Frequenza del rumore, più bassa = dune più grandi
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	# Aggiungi un nodo per organizzare i blocchi nella Scena
	if not is_instance_valid(chunks_parent):
		chunks_parent = Node3D.new()
		chunks_parent.name = "ChunksParent"
		add_child(chunks_parent)

	# Avvia la generazione
	update_chunks()

# --- Funzioni Principali ---

func _process(_delta):
	if Engine.is_editor_hint():
		return
		
	# Assicurati di avere la posizione del giocatore.
	# Sostituisci questo con la logica per ottenere la posizione del tuo Player
	# Esempio: player_position = get_node("/root/MainScene/Player").global_position
	
	# Aggiorna i blocchi ad ogni frame (puoi usare un timer per ottimizzare)
	update_chunks()

## Calcola il blocco (Chunk) in cui si trova il giocatore
func get_player_chunk_coords() -> Vector2:
	var player_position = player.global_position
	var chunk_x = floor(player_position.x / (CHUNK_SIZE * VERTEX_SCALE))
	var chunk_z = floor(player_position.z / (CHUNK_SIZE * VERTEX_SCALE))
	return Vector2(chunk_x, chunk_z)

## Gestisce la generazione e la rimozione dei blocchi
func update_chunks():
	var current_chunk = get_player_chunk_coords()
	var new_chunks_to_keep: Dictionary = {}

	# 1. Determina quali blocchi devono esistere
	for x in range(-CHUNK_AREA, CHUNK_AREA + 1):
		for z in range(-CHUNK_AREA, CHUNK_AREA + 1):
			var cx = int(current_chunk.x) + x
			var cz = int(current_chunk.y) + z
			var key = Vector2(cx, cz)

			if not generated_chunks.has(key):
				# Genera un nuovo blocco se non esiste
				var new_chunk = create_chunk(cx, cz)
				generated_chunks[key] = new_chunk
			
			new_chunks_to_keep[key] = generated_chunks[key]

	# 2. Rimuovi i vecchi blocchi fuori dal raggio
	for key in generated_chunks.keys():
		if not new_chunks_to_keep.has(key):
			# Rimuovi il blocco dalla scena e libera la memoria
			generated_chunks[key].queue_free()
			generated_chunks.erase(key)

## Genera la Mesh 3D di un singolo blocco
func create_chunk(chunk_x: int, chunk_z: int) -> MeshInstance3D:
	var mesh_array = ArrayMesh.new()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)

	# Tipi Packed*Array richiesti da Godot 4 per le mesh
	var vertices: PackedVector3Array = []
	var indices: PackedInt32Array = []
	var uvs: PackedVector2Array = []

	var offset_x = chunk_x * (CHUNK_SIZE - 1) * VERTEX_SCALE
	var offset_z = chunk_z * (CHUNK_SIZE - 1) * VERTEX_SCALE

	# 1. Generazione dei Vertici
	for x in range(CHUNK_SIZE):
		for z in range(CHUNK_SIZE):
			var global_x = x * VERTEX_SCALE + offset_x
			var global_z = z * VERTEX_SCALE + offset_z
			
			# Calcola l'altezza utilizzando il rumore
			var noise_value = noise.get_noise_2d(global_x, global_z)
			var height = noise_value * HEIGHT_SCALE
			
			vertices.append(Vector3(global_x, height, global_z))
			
			# Aggiungi UV
			var uv_x = float(x) / (CHUNK_SIZE - 1)
			var uv_z = float(z) / (CHUNK_SIZE - 1)
			uvs.append(Vector2(uv_x, uv_z))

	# 2. Creazione degli Indici (Triangoli)
	for x in range(CHUNK_SIZE - 1):
		for z in range(CHUNK_SIZE - 1):
			# Indici dei vertici del quadrilatero
			var i0 = x * CHUNK_SIZE + z
			var i1 = (x + 1) * CHUNK_SIZE + z
			var i2 = x * CHUNK_SIZE + z + 1
			var i3 = (x + 1) * CHUNK_SIZE + z + 1

			# Primo triangolo (i0, i1, i2)
			indices.append(i0)
			indices.append(i1)
			indices.append(i2)

			# Secondo triangolo (i2, i1, i3)
			indices.append(i2)
			indices.append(i1)
			indices.append(i3)

	# 3. Assemblaggio della Mesh e Calcolo delle Normali
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	
	# Aggiungi la superficie alla Mesh
	mesh_array.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	# Calcola automaticamente le normali per l'illuminazione e le ombre
	var array_tool = MeshDataTool.new()
	array_tool.create_from_surface(mesh_array, 0)
	array_tool.commit_to_surface(mesh_array, 0) # Calcola normali e tangenti
	
	# 4. Configurazione del Nodo
	var chunk = MeshInstance3D.new()
	chunk.mesh = mesh_array
	
	# Materiale del Deserto (Sabbia)
	var material = StandardMaterial3D.new()
	material.albedo_color = Color("#EED590") # Colore sabbia
	material.roughness = 0.8
	material.metallic = 0.05
	chunk.material_override = material

	# 5. Aggiunta della Collisione
	var shape = ConcavePolygonShape3D.new()
	# Usa l'array di vertici per creare la forma di collisione
	shape.set_faces(vertices) 
	
	var body = StaticBody3D.new()
	var collision = CollisionShape3D.new()
	collision.shape = shape
	
	body.add_child(collision)
	chunk.add_child(body)
	
	chunks_parent.add_child(chunk)
	return chunk
