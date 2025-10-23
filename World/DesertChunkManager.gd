@tool
extends Node3D
class_name DesertChunkManager

## Gestisce il caricamento e scaricamento dei chunk del deserto

@export_group("Editor Preview")
@export_tool_button("Generate Preview") var _generate_preview = generate_preview
@export_tool_button("Clear Preview") var _clear_preview = clear_preview
@export var preview_center: Vector3 = Vector3.ZERO
@export var preview_chunks: int = 2

@export_group("Chunk Settings")
@export var chunk_size: float = 50.0:
	set(value):
		chunk_size = value
		if Engine.is_editor_hint():
			regenerate_preview()
@export var render_distance: int = 3  # Numero di chunk visibili in ogni direzione
@export var chunk_height: float = 10.0
@export var noise_scale: float = 0.1:
	set(value):
		noise_scale = value
		if Engine.is_editor_hint():
			regenerate_preview()
@export var noise_amplitude: float = 5.0:
	set(value):
		noise_amplitude = value
		if Engine.is_editor_hint():
			regenerate_preview()

@export_group("References")
@export var player: Node3D

@export_group("Materials")
@export var desert_material: Material

var loaded_chunks: Dictionary = {}  # Vector2i -> Node3D
var noise: FastNoiseLite
var last_player_chunk: Vector2i = Vector2i(999999, 999999)

func _ready() -> void:
	# Inizializza il noise con seed fisso per terreno deterministico
	noise = FastNoiseLite.new()
	noise.seed = 12345
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = noise_scale
	
	# Se siamo nell'editor, non fare nulla (usa il pulsante Generate Preview)
	if Engine.is_editor_hint():
		return
	
	if not player:
		push_error("Player non assegnato!")
		return
	
	# Carica i chunk iniziali
	update_chunks()

func _process(_delta: float) -> void:
	# Non processare nell'editor
	if Engine.is_editor_hint():
		return
		
	if not player:
		return
	
	var current_chunk = world_to_chunk(player.global_position)
	
	# Aggiorna solo se il player è cambiato chunk
	if current_chunk != last_player_chunk:
		last_player_chunk = current_chunk
		update_chunks()

func world_to_chunk(pos: Vector3) -> Vector2i:
	return Vector2i(
		int(floor(pos.x / chunk_size)),
		int(floor(pos.z / chunk_size))
	)

func chunk_to_world(chunk_pos: Vector2i) -> Vector3:
	return Vector3(
		chunk_pos.x * chunk_size,
		0,
		chunk_pos.y * chunk_size
	)

func update_chunks() -> void:
	var player_chunk = world_to_chunk(player.global_position)
	var chunks_to_keep: Array[Vector2i] = []
	
	# Determina quali chunk dovrebbero essere caricati
	for x in range(-render_distance, render_distance + 1):
		for z in range(-render_distance, render_distance + 1):
			var chunk_pos = player_chunk + Vector2i(x, z)
			chunks_to_keep.append(chunk_pos)
			
			if not loaded_chunks.has(chunk_pos):
				load_chunk(chunk_pos)
	
	# Rimuovi chunk troppo lontani
	var chunks_to_unload: Array[Vector2i] = []
	for chunk_pos in loaded_chunks.keys():
		if chunk_pos not in chunks_to_keep:
			chunks_to_unload.append(chunk_pos)
	
	for chunk_pos in chunks_to_unload:
		unload_chunk(chunk_pos)

func load_chunk(chunk_pos: Vector2i) -> void:
	var chunk = create_chunk(chunk_pos)
	loaded_chunks[chunk_pos] = chunk
	add_child(chunk)

func unload_chunk(chunk_pos: Vector2i) -> void:
	if loaded_chunks.has(chunk_pos):
		var chunk = loaded_chunks[chunk_pos]
		loaded_chunks.erase(chunk_pos)
		chunk.queue_free()

func create_chunk(chunk_pos: Vector2i) -> Node3D:
	var chunk = Node3D.new()
	chunk.name = "Chunk_%d_%d" % [chunk_pos.x, chunk_pos.y]
	
	var world_pos = chunk_to_world(chunk_pos)
	chunk.position = world_pos
	
	# Crea il mesh del terreno
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = generate_terrain_mesh(chunk_pos)
	
	if desert_material:
		mesh_instance.material_override = desert_material
	
	chunk.add_child(mesh_instance)
	
	# Aggiungi collisione
	var static_body = StaticBody3D.new()
	var collision_shape = CollisionShape3D.new()
	collision_shape.shape = mesh_instance.mesh.create_trimesh_shape()
	
	static_body.add_child(collision_shape)
	chunk.add_child(static_body)
	
	return chunk

func generate_terrain_mesh(chunk_pos: Vector2i) -> ArrayMesh:
	var resolution = 60  # Vertici per lato del chunk
	var surface_tool = SurfaceTool.new()
	
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Genera i vertici con altezza basata sul noise
	for z in range(resolution + 1):
		for x in range(resolution + 1):
			var local_x = (x / float(resolution)) * chunk_size
			var local_z = (z / float(resolution)) * chunk_size
			
			# Coordinate mondiali per il noise
			var world_x = chunk_pos.x * chunk_size + local_x
			var world_z = chunk_pos.y * chunk_size + local_z
			
			var height = get_terrain_height(world_x, world_z)
			
			var vertex = Vector3(local_x, height, local_z)
			var normal = calculate_normal(world_x, world_z)
			var uv = Vector2(x / float(resolution), z / float(resolution))
			
			surface_tool.set_normal(normal)
			surface_tool.set_uv(uv)
			surface_tool.add_vertex(vertex)
	
	# Genera gli indici per i triangoli
	for z in range(resolution):
		for x in range(resolution):
			var i = z * (resolution + 1) + x
			
			# Primo triangolo (ordine invertito per normale corretta)
			surface_tool.add_index(i)
			surface_tool.add_index(i + 1)
			surface_tool.add_index(i + resolution + 1)
			
			# Secondo triangolo (ordine invertito per normale corretta)
			surface_tool.add_index(i + 1)
			surface_tool.add_index(i + resolution + 2)
			surface_tool.add_index(i + resolution + 1)
	
	# NON chiamare generate_normals() - usiamo le normali calcolate manualmente
	return surface_tool.commit()

func get_terrain_height(world_x: float, world_z: float) -> float:
	# Combina diverse ottave di noise per un terreno più interessante
	var height = 0.0
	height += noise.get_noise_2d(world_x, world_z) * noise_amplitude
	height += noise.get_noise_2d(world_x * 2, world_z * 2) * (noise_amplitude * 0.5)
	height += noise.get_noise_2d(world_x * 4, world_z * 4) * (noise_amplitude * 0.25)
	return height

func calculate_normal(world_x: float, world_z: float) -> Vector3:
	var offset = 1.0  # Aumentato per campionamento più stabile
	var h_right = get_terrain_height(world_x + offset, world_z)
	var h_left = get_terrain_height(world_x - offset, world_z)
	var h_forward = get_terrain_height(world_x, world_z + offset)
	var h_back = get_terrain_height(world_x, world_z - offset)
	
	# Calcola la normale usando differenze centrali per maggiore precisione
	var tangent_x = Vector3(offset * 2, h_right - h_left, 0).normalized()
	var tangent_z = Vector3(0, h_forward - h_back, offset * 2).normalized()
	
	return tangent_z.cross(tangent_x).normalized()

func update_editor_preview() -> void:
	# Inizializza il noise se non esiste
	if not noise:
		noise = FastNoiseLite.new()
		noise.seed = 12345
		noise.noise_type = FastNoiseLite.TYPE_PERLIN
		noise.frequency = noise_scale
	
	# Rimuovi tutti i chunk esistenti
	clear_all_chunks()
	
	# Genera chunk attorno al preview_center
	var center_chunk = world_to_chunk(preview_center)
	
	for x in range(-preview_chunks, preview_chunks + 1):
		for z in range(-preview_chunks, preview_chunks + 1):
			var chunk_pos = center_chunk + Vector2i(x, z)
			var chunk = create_chunk(chunk_pos)
			loaded_chunks[chunk_pos] = chunk
			add_child(chunk)
			
			# Imposta l'owner per tutti i nodi figli nell'editor
			if get_tree() and get_tree().edited_scene_root:
				chunk.owner = get_tree().edited_scene_root
				for child in chunk.get_children():
					child.owner = get_tree().edited_scene_root
					for subchild in child.get_children():
						subchild.owner = get_tree().edited_scene_root

func clear_all_chunks() -> void:
	for chunk in loaded_chunks.values():
		if is_instance_valid(chunk):
			remove_child(chunk)
			chunk.queue_free()
	loaded_chunks.clear()

# Funzione chiamata dal pulsante nell'editor
func generate_preview() -> void:
	if Engine.is_editor_hint():
		update_editor_preview()

func clear_preview() -> void:
	if Engine.is_editor_hint():
		clear_all_chunks()

func regenerate_preview() -> void:
	# Rigenera solo se ci sono già chunk caricati
	if Engine.is_editor_hint() and loaded_chunks.size() > 0:
		# Aggiorna la frequenza del noise
		if noise:
			noise.frequency = noise_scale
		update_editor_preview()
