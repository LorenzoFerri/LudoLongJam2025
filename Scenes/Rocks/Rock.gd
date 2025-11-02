@tool
extends StaticBody3D

class_name Rock

const RAY_LENGTH: float = 100.0
const RAY_OFFSET: float = 5  # Distanza di 0.5 metri dal centro per ogni raggio

const RAY_OFFSETS: Array[Vector3] = [
	Vector3(RAY_OFFSET, 0, RAY_OFFSET),
	Vector3(-RAY_OFFSET, 0, RAY_OFFSET),
	Vector3(RAY_OFFSET, 0, -RAY_OFFSET),
	Vector3(-RAY_OFFSET, 0, -RAY_OFFSET)
]

# --- Funzione di Raycast Multiplo e Media ---

func get_average_hit_data() -> Dictionary:
	var total_normal: Vector3 = Vector3.ZERO
	var total_position: Vector3 = Vector3.ZERO
	var successful_hits: int = 0
	
	var space_state = get_world_3d().direct_space_state

	for offset in RAY_OFFSETS:
		# L'origine del raggio parte dall'origine del nodo + offset
		var origin: Vector3 = global_transform.origin + offset
		var target: Vector3 = origin + Vector3.DOWN * RAY_LENGTH
		
		var query = PhysicsRayQueryParameters3D.create(origin, target)
		query.collide_with_areas = true
		query.collide_with_bodies = true
		query.exclude = [get_rid()] 
		
		var result = space_state.intersect_ray(query)
		
		if not result.is_empty():
			total_normal += result.normal
			total_position += result.position
			successful_hits += 1

	if successful_hits == 0:
		return {}
	
	return {
		"position": total_position / successful_hits,
		"normal": (total_normal / successful_hits).normalized()
	}

# --- Logica di Allineamento nel _ready() ---

func _ready():
	if Engine.is_editor_hint() and not is_instance_valid(self):
		return
		
	var hit_data = get_average_hit_data()
	
	if hit_data.is_empty():
		return
		
	var normal: Vector3 = hit_data.normal
	var hit_position: Vector3 = hit_data.position
	
	# 1. Sposta l'origine (pivot a raso terra) della roccia al punto di collisione medio.
	# Questo la posiziona direttamente sulla superficie del terreno.
	global_transform.origin = hit_position
	
	# 2. Calcola la nuova trasformazione usando la normale come vettore 'UP'.
	# Usiamo la trasformazione attuale per mantenere l'orientamento orizzontale originale,
	# ma forziamo l'asse Y (Up) a seguire la normale.
	var current_transform = global_transform
	
	# look_at (o la sua logica) crea una nuova Base: 
	# - Il -Z (Forward) punta verso 'target'
	# - Il Y (Up) punta verso 'up_direction' (normal)
	# Utilizziamo la base, non l'intera transform, per evitare di spostare l'origine.
	var new_basis = Basis.looking_at(
		-current_transform.basis.z, # Direzione Forward (mantiene l'orientamento attuale)
		normal                      # La Normale è il nuovo 'Up'
	)
	
	global_transform.basis = new_basis
	
	# 3. Rotazione Correttiva (perché la Normal è ora Y, non -Z)
	# Applica una rotazione sull'asse X (locale) di -90 gradi.
	# Questo sposta il vettore che *guarda* la normale dall'asse -Z all'asse Y.
	#rotate_object_local(Vector3.RIGHT, deg_to_rad(-90))
	
	# 4. Rotazione Casuale (Roll) attorno alla normale (che è l'asse Y locale)
	rotate_object_local(Vector3.UP, deg_to_rad(randi_range(0, 360)))
