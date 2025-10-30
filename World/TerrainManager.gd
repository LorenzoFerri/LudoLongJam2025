@tool
extends Node3D
class_name TerrainManager

var goal_scene = preload("res://Goals/Goal.tscn")

## Gestisce la generazione e il caricamento dei chunk del terreno infinito

# Riferimenti
@export var player: Node3D
@export var chunk_material: Material = null
@export_group("Chunk Settings")
@export var chunk_size: int = 32
@export var chunk_resolution: int = 16:
	set(value):
		chunk_resolution = max(2, value)
		if Engine.is_editor_hint() and preview_enabled:
			_update_preview()
@export var chunk_render_distance: int = 3
@export var chunk_height: float = 20.0

@export_group("Noise Settings")
@export var noise_scale: float = 0.05:
	set(value):
		noise_scale = value
		if Engine.is_editor_hint() and preview_enabled:
			_update_preview()
@export var noise_octaves: int = 4:
	set(value):
		noise_octaves = value
		if Engine.is_editor_hint() and preview_enabled:
			_update_preview()
@export var noise_persistence: float = 0.5:
	set(value):
		noise_persistence = value
		if Engine.is_editor_hint() and preview_enabled:
			_update_preview()
@export var noise_lacunarity: float = 2.0:
	set(value):
		noise_lacunarity = value
		if Engine.is_editor_hint() and preview_enabled:
			_update_preview()
@export var noise_seed: int = 0:
	set(value):
		noise_seed = value
		if Engine.is_editor_hint() and preview_enabled:
			_update_preview()

@export_group("Layer 1 - Base Terrain")
@export var layer1_enabled: bool = true:
	set(value):
		layer1_enabled = value
		if Engine.is_editor_hint() and preview_enabled:
			_update_preview()
@export var layer1_scale: float = 0.03:
	set(value):
		layer1_scale = value
		if Engine.is_editor_hint() and preview_enabled:
			_update_preview()
@export var layer1_amplitude: float = 10.0:
	set(value):
		layer1_amplitude = value
		if Engine.is_editor_hint() and preview_enabled:
			_update_preview()

@export_group("Layer 2 - Medium Details")
@export var layer2_enabled: bool = true:
	set(value):
		layer2_enabled = value
		if Engine.is_editor_hint() and preview_enabled:
			_update_preview()
@export var layer2_scale: float = 0.08:
	set(value):
		layer2_scale = value
		if Engine.is_editor_hint() and preview_enabled:
			_update_preview()
@export var layer2_amplitude: float = 5.0:
	set(value):
		layer2_amplitude = value
		if Engine.is_editor_hint() and preview_enabled:
			_update_preview()

@export_group("Layer 3 - Fine Details")
@export var layer3_enabled: bool = true:
	set(value):
		layer3_enabled = value
		if Engine.is_editor_hint() and preview_enabled:
			_update_preview()
@export var layer3_scale: float = 0.15:
	set(value):
		layer3_scale = value
		if Engine.is_editor_hint() and preview_enabled:
			_update_preview()
@export var layer3_amplitude: float = 2.0:
	set(value):
		layer3_amplitude = value
		if Engine.is_editor_hint() and preview_enabled:
			_update_preview()

@export_group("Editor Preview")
@export var preview_enabled: bool = false:
	set(value):
		preview_enabled = value
		if Engine.is_editor_hint():
			_update_preview()
@export var preview_chunks_x: int = 3:
	set(value):
		preview_chunks_x = max(1, value)
		if Engine.is_editor_hint() and preview_enabled:
			_update_preview()
@export var preview_chunks_z: int = 3:
	set(value):
		preview_chunks_z = max(1, value)
		if Engine.is_editor_hint() and preview_enabled:
			_update_preview()
@export var preview_center: Vector2i = Vector2i(0, 0):
	set(value):
		preview_center = value
		if Engine.is_editor_hint() and preview_enabled:
			_update_preview()

@export_group("Goals Settings")
@export var goals_enabled: bool = true
@export var goal_distance_from_player: float = 500.0
@export var goal_separation_distance: float = 250.0
@export var number_of_goals: int = 3


# Variabili interne
var loaded_chunks: Dictionary = {}
var preview_chunks: Dictionary = {}
var chunk_thread: Thread
var mutex: Mutex
var semaphore: Semaphore
var should_exit: bool = false
var chunks_to_generate: Array = []
var generated_chunks: Array = []

# Noise generators
var noise1: FastNoiseLite
var noise2: FastNoiseLite
var noise3: FastNoiseLite

func _ready() -> void:
	if Engine.is_editor_hint():
		_setup_noise()
		if preview_enabled:
			_update_preview()
		return
	
	_setup_noise()
	_setup_threading()
	_initial_chunk_load()
	
	if goals_enabled:
		_spawn_goals()

	seed(noise_seed)

func _setup_noise() -> void:
	# Layer 1 - Terrain di base
	noise1 = FastNoiseLite.new()
	noise1.seed = noise_seed
	noise1.noise_type = FastNoiseLite.TYPE_PERLIN
	noise1.frequency = layer1_scale
	noise1.fractal_octaves = noise_octaves
	noise1.fractal_lacunarity = noise_lacunarity
	noise1.fractal_gain = noise_persistence
	
	# Layer 2 - Dettagli medi
	noise2 = FastNoiseLite.new()
	noise2.seed = noise_seed + 1000
	noise2.noise_type = FastNoiseLite.TYPE_PERLIN
	noise2.frequency = layer2_scale
	noise2.fractal_octaves = max(1, noise_octaves - 1)
	
	# Layer 3 - Dettagli fini
	noise3 = FastNoiseLite.new()
	noise3.seed = noise_seed + 2000
	noise3.noise_type = FastNoiseLite.TYPE_PERLIN
	noise3.frequency = layer3_scale
	noise3.fractal_octaves = max(1, noise_octaves - 2)

func _setup_threading() -> void:
	mutex = Mutex.new()
	semaphore = Semaphore.new()
	chunk_thread = Thread.new()
	chunk_thread.start(_chunk_generation_thread)

func _initial_chunk_load() -> void:
	if not player:
		push_error("Player non assegnato!")
		return
	
	var player_chunk := _get_chunk_position(player.global_position)
	_request_chunks_around(player_chunk)

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
		
	if not player:
		return
	
	_process_generated_chunks()
	_update_chunks()

func _update_chunks() -> void:
	var player_chunk := _get_chunk_position(player.global_position)
	var chunks_needed: Array = []
	
	# Trova i chunk necessari
	for x in range(-chunk_render_distance, chunk_render_distance + 1):
		for z in range(-chunk_render_distance, chunk_render_distance + 1):
			var chunk_pos := Vector2i(player_chunk.x + x, player_chunk.y + z)
			chunks_needed.append(chunk_pos)
			
			# Se il chunk non esiste, richiedilo
			if not loaded_chunks.has(chunk_pos):
				_request_chunk_generation(chunk_pos)
	
	# Rimuovi chunk troppo lontani
	var chunks_to_remove: Array = []
	for chunk_pos in loaded_chunks.keys():
		if not chunks_needed.has(chunk_pos):
			chunks_to_remove.append(chunk_pos)
	
	for chunk_pos in chunks_to_remove:
		_unload_chunk(chunk_pos)

func _request_chunks_around(center: Vector2i) -> void:
	for x in range(-chunk_render_distance, chunk_render_distance + 1):
		for z in range(-chunk_render_distance, chunk_render_distance + 1):
			var chunk_pos := Vector2i(center.x + x, center.y + z)
			_request_chunk_generation(chunk_pos)

func _request_chunk_generation(chunk_pos: Vector2i) -> void:
	mutex.lock()
	if not chunks_to_generate.has(chunk_pos):
		chunks_to_generate.append(chunk_pos)
		semaphore.post()
	mutex.unlock()

func _chunk_generation_thread() -> void:
	while true:
		semaphore.wait()
		
		if should_exit:
			break
		
		mutex.lock()
		if chunks_to_generate.is_empty():
			mutex.unlock()
			continue
		
		var chunk_pos: Vector2i = chunks_to_generate.pop_front()
		mutex.unlock()
		
		# Genera il chunk
		var chunk_data := _generate_chunk_data(chunk_pos)
		
		mutex.lock()
		generated_chunks.append(chunk_data)
		mutex.unlock()

func _generate_chunk_data(chunk_pos: Vector2i) -> Dictionary:
	var heightmap: Array = []
	var world_x := chunk_pos.x * chunk_size
	var world_z := chunk_pos.y * chunk_size
	
	# Usa chunk_resolution invece di chunk_size per la mesh
	var step := float(chunk_size) / float(chunk_resolution)
	
	for z in range(chunk_resolution + 1):
		var row: Array = []
		for x in range(chunk_resolution + 1):
			var wx := world_x + (x * step)
			var wz := world_z + (z * step)
			var height := _calculate_height(int(wx), int(wz))
			row.append(height)
		heightmap.append(row)
	
	return {
		"position": chunk_pos,
		"heightmap": heightmap,
		"resolution": chunk_resolution
	}

func _calculate_height(x: int, z: int) -> float:
	var height := 0.0
	
	if layer1_enabled:
		height += noise1.get_noise_2d(x, z) * layer1_amplitude
	
	if layer2_enabled:
		height += noise2.get_noise_2d(x, z) * layer2_amplitude
	
	if layer3_enabled:
		height += noise3.get_noise_2d(x, z) * layer3_amplitude
	
	return height

func _process_generated_chunks() -> void:
	mutex.lock()
	var chunks_ready := generated_chunks.duplicate()
	generated_chunks.clear()
	mutex.unlock()
	
	for chunk_data in chunks_ready:
		_create_chunk_mesh(chunk_data)

func _create_chunk_mesh(chunk_data: Dictionary) -> void:
	var chunk_pos: Vector2i = chunk_data["position"]
	var heightmap: Array = chunk_data["heightmap"]
	var resolution: int = chunk_data["resolution"]
	
	# Crea il nodo del chunk
	var chunk := TerrainChunk.new()
	chunk.name = "Chunk_%d_%d" % [chunk_pos.x, chunk_pos.y]
	chunk.position = Vector3(chunk_pos.x * chunk_size, 0, chunk_pos.y * chunk_size)
	
	# Genera la mesh passando la funzione per calcolare le altezze e il seed
	chunk.generate_mesh(heightmap, chunk_size, resolution, chunk_material, _calculate_height, chunk_pos, noise_seed)
	
	# Aggiungi alla scena
	add_child(chunk)
	loaded_chunks[chunk_pos] = chunk

func _unload_chunk(chunk_pos: Vector2i) -> void:
	if loaded_chunks.has(chunk_pos):
		var chunk = loaded_chunks[chunk_pos]
		chunk.queue_free()
		loaded_chunks.erase(chunk_pos)

func _get_chunk_position(world_pos: Vector3) -> Vector2i:
	return Vector2i(
		floori(world_pos.x / chunk_size),
		floori(world_pos.z / chunk_size)
	)

func _exit_tree() -> void:
	if Engine.is_editor_hint():
		_clear_preview()
		return
		
	should_exit = true
	semaphore.post()
	chunk_thread.wait_to_finish()

func _update_preview() -> void:
	_clear_preview()
	
	if not preview_enabled:
		return
	
	_setup_noise()
	
	var half_x := float(preview_chunks_x) / 2.0
	var half_z := float(preview_chunks_z) / 2.0
	
	for x in range(preview_chunks_x):
		for z in range(preview_chunks_z):
			var chunk_pos := Vector2i(
				int(preview_center.x + x - half_x),
				int(preview_center.y + z - half_z)
			)
			
			var chunk_data := _generate_chunk_data(chunk_pos)
			_create_preview_chunk(chunk_data)

func _create_preview_chunk(chunk_data: Dictionary) -> void:
	var chunk_pos: Vector2i = chunk_data["position"]
	var heightmap: Array = chunk_data["heightmap"]
	var resolution: int = chunk_data["resolution"]
	
	var chunk := TerrainChunk.new()
	chunk.name = "PreviewChunk_%d_%d" % [chunk_pos.x, chunk_pos.y]
	chunk.position = Vector3(chunk_pos.x * chunk_size, 0, chunk_pos.y * chunk_size)
	
	# Genera la mesh passando la funzione per calcolare le altezze e il seed
	chunk.generate_mesh(heightmap, chunk_size, resolution, chunk_material, _calculate_height, chunk_pos, noise_seed)
	
	add_child(chunk)
	
	# Imposta owner solo se siamo in una scena valida
	if Engine.is_editor_hint() and get_tree() and get_tree().edited_scene_root:
		chunk.owner = get_tree().edited_scene_root
	
	preview_chunks[chunk_pos] = chunk

func _clear_preview() -> void:
	for chunk in preview_chunks.values():
		if is_instance_valid(chunk):
			chunk.queue_free()
	preview_chunks.clear()

func _spawn_goals() -> void:
	if not player:
		push_warning("Cannot spawn goals: player not assigned.")
		return

	var rng = RandomNumberGenerator.new()
	rng.seed = noise_seed + 1234
	var dir = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized()
	var player_pos = Vector3(0, 0, 0)

	for i in range(number_of_goals):
		var offset_dir := dir.rotated(deg_to_rad(rng.randf_range(-10, 10))) # small random spread
		var distance := goal_distance_from_player + rng.randi_range(-50, 150) + (i * (goal_separation_distance))
		var goal_pos_2d := Vector2(player_pos.x, player_pos.z) + offset_dir * distance

		# Calculate height using terrain noise
		var y := _calculate_height(int(goal_pos_2d.x), int(goal_pos_2d.y))

		# Create goal node
		var goal: Goal = goal_scene.instantiate()
		goal.name = "Goal_%d" % i
		goal.position = Vector3(goal_pos_2d.x, y + 2.0, goal_pos_2d.y) # slightly above ground
		add_child(goal)
		get_parent().add_goal(goal)
		
		
