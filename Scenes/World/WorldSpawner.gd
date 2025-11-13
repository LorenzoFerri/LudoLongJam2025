extends Node3D
class_name WorldSpawner

@export var terrain_manager: TerrainManager
var world_seed: int = 12345

# Macro layer — huge features (e.g. big rocks, ruins)
@export var goals_cell_size: int = 1024
@export var goals_scenes: Array[PackedScene] = [
	preload("res://Scenes/Goals/Goal.tscn")
]
@export var goals_spawn_threshold: float = 0.45
var goals_data = {}

# Micro layer — local small props (rocks, plants, etc.)
@export var micro_noise_frequency: float = 0.02
@export var micro_scenes: Array[PackedScene] = [
	preload("res://Scenes/Rocks/BigRock1.tscn"),
	preload("res://Scenes/Rocks/BigRock2.tscn"),
	preload("res://Scenes/Rocks/BigRock3.tscn"),
	preload("res://Scenes/Rocks/MediumRock1.tscn"),
	preload("res://Scenes/Rocks/MediumRock2.tscn"),
	preload("res://Scenes/Rocks/MediumRock3.tscn"),
	preload("res://Scenes/Rocks/MediumRock4.tscn"),
	preload("res://Scenes/Rocks/MediumRock5.tscn"),
	preload("res://Scenes/Rocks/SmallRock1.tscn"),
	preload("res://Scenes/Rocks/SmallRock2.tscn"),
	preload("res://Scenes/Rocks/SmallRock3.tscn"),
	preload("res://Scenes/Rocks/SmallRock4.tscn"),
	preload("res://Scenes/Rocks/SmallRock5.tscn"),
	preload("res://Scenes/Rocks/SmallRock6.tscn")
]
@export var micro_threshold: float = 0.67
var micro_data = {}

# Internal data
var _goals_noise: FastNoiseLite
var _micro_noise: FastNoiseLite
var _spawned_goals: Dictionary = {}  # key = macro cell coords
var _spawned_micro_objects: Dictionary = {}   # key = chunk_pos -> [nodes]


func _ready():
	if not terrain_manager:
		push_error("WorldSpawner: terrain_manager not assigned.")
		return

	terrain_manager.chunk_loaded.connect(_on_chunk_loaded)
	terrain_manager.chunk_unloaded.connect(_on_chunk_unloaded)
	
	world_seed = terrain_manager.noise_seed
	seed(world_seed + 123)

	_setup_noise()


var despawn_cooldown := 0.0

func _process(delta: float) -> void:
	if despawn_cooldown <= 0:
		_unload_goals_far_from_player()
		despawn_cooldown = 0.5
	else:
		despawn_cooldown -= delta



func _on_chunk_loaded(chunk_pos: Vector2i, _chunk: Node3D):
	_spawn_goals_around(chunk_pos)
	_spawn_micro_objects_for_chunk(chunk_pos)


func _on_chunk_unloaded(chunk_pos: Vector2i):
	if not _spawned_micro_objects.has(chunk_pos):
		return

	var chunk_size = terrain_manager.chunk_size
	var world_origin = Vector2i(chunk_pos.x * chunk_size, chunk_pos.y * chunk_size)

	# Remove the actual nodes
	for obj in _spawned_micro_objects[chunk_pos]:
		if is_instance_valid(obj):
			obj.queue_free()

	_spawned_micro_objects.erase(chunk_pos)

	# Clean micro_data entries for this chunk area
	for x in range(0, chunk_size, 4):
		for z in range(0, chunk_size, 4):
			var wx = world_origin.x + x
			var wz = world_origin.y + z
			micro_data.erase(Vector2i(wx, wz))

	


func _setup_noise():
	_goals_noise = FastNoiseLite.new()
	_goals_noise.seed = world_seed
	_goals_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_goals_noise.frequency = 1.0 / float(goals_cell_size)

	_micro_noise = FastNoiseLite.new()
	_micro_noise.seed = world_seed + 9999
	_micro_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_micro_noise.frequency = micro_noise_frequency


func _spawn_goals_around(chunk_pos: Vector2i):
	# Determine which macro cells overlap this chunk
	var chunk_size = terrain_manager.chunk_size
	var world_chunk_origin = Vector2(chunk_pos.x * chunk_size, chunk_pos.y * chunk_size)

	var start_cell = Vector2i(floor(world_chunk_origin.x / goals_cell_size), floor(world_chunk_origin.y / goals_cell_size))
	var end_cell = Vector2i(floor((world_chunk_origin.x + chunk_size) / goals_cell_size), floor((world_chunk_origin.y + chunk_size) / goals_cell_size))

	for cx in range(start_cell.x, end_cell.x + 1):
		for cz in range(start_cell.y, end_cell.y + 1):
			var cell_coords = Vector2i(cx, cz)
			
			if _spawned_goals.has(cell_coords) and is_instance_valid(_spawned_goals[cell_coords]):
				continue
			elif _spawned_goals.has(cell_coords) and not is_instance_valid(_spawned_goals[cell_coords]):
				_spawned_goals.erase(cell_coords)

			#var val = _goals_noise.get_noise_2d(cx, cz)
			var world_x = float(cx) * goals_cell_size
			var world_z = float(cz) * goals_cell_size
			var val = _goals_noise.get_noise_2d(world_x, world_z)

			if val > goals_spawn_threshold:
				_spawn_goal(cell_coords)

func _spawn_goal(cell_coords: Vector2i):
	var rng = RandomNumberGenerator.new()
	rng.seed = world_seed + hash(cell_coords)

	var cell_origin = Vector3(cell_coords.x * goals_cell_size, 0, cell_coords.y * goals_cell_size)
	var offset = Vector3(
		rng.randf_range(0, goals_cell_size),
		0,
		rng.randf_range(0, goals_cell_size)
	)

	var world_pos = cell_origin + offset

	var tm = terrain_manager
	var y = tm._calculate_height(int(world_pos.x), int(world_pos.z))
	world_pos.y = y

	if not goals_data.has(cell_coords):
		var picked_scene = goals_scenes.pick_random()
		var instance = picked_scene.instantiate()
		instance.position = world_pos
		instance.rotation.y = randf_range(0.0, TAU)
		add_child(instance, true)
		_spawned_goals[cell_coords] = instance
		goals_data[cell_coords] = {
			"picked_scene": picked_scene,
			"rotation": instance.rotation,
			"was_reached": false,
		}
	else:
		var data = goals_data[cell_coords]
		var instance = data.picked_scene.instantiate()
		instance.position = world_pos
		instance.rotation = data.rotation
		add_child(instance, true)
		_spawned_goals[cell_coords] = instance
		instance.was_reached = data.was_reached


func _unload_goals_far_from_player():
	var tm = terrain_manager
	var chunk_size = tm.chunk_size
	var active_radius = float(tm.chunk_render_distance + 1) * chunk_size

	var player_pos_2d = Vector2(tm.player.global_position.x, tm.player.global_position.z)

	for cell_coords in _spawned_goals.keys():
		var inst = _spawned_goals[cell_coords]
		if not is_instance_valid(inst):
			_spawned_goals.erase(cell_coords)
			continue

		var goal_center = Vector2(
			cell_coords.x * goals_cell_size + goals_cell_size / 2,
			cell_coords.y * goals_cell_size + goals_cell_size / 2
		)

		var dist = goal_center.distance_to(player_pos_2d)
		if dist > active_radius * 3.0:
			inst.queue_free()
			_spawned_goals.erase(cell_coords)

	
func _spawn_micro_objects_for_chunk(chunk_pos: Vector2i):
	var tm = terrain_manager
	if not tm.loaded_chunks.has(chunk_pos):
		return

	var chunk = tm.loaded_chunks[chunk_pos]
	var chunk_size = tm.chunk_size
	var world_origin = Vector2(chunk_pos.x * chunk_size, chunk_pos.y * chunk_size)
	var objects = []

	# wait 2 frames to ensure terrain collision is ready
	await get_tree().process_frame
	await get_tree().process_frame

	for x in range(0, chunk_size, 4):
		for z in range(0, chunk_size, 4):
			var wx = int(world_origin.x + x)
			var wz = int(world_origin.y + z)
			var pos_key = Vector2i(wx, wz)

			var n = _micro_noise.get_noise_2d(wx, wz)
			if n <= micro_threshold:
				continue

			# initial guess
			var y = tm._calculate_height(wx, wz)

			# precise terrain surface using raycast
			var start = Vector3(wx, y + 200.0, wz)
			var end = Vector3(wx, y - 500.0, wz)
			var query = PhysicsRayQueryParameters3D.create(start, end)
			query.collide_with_areas = false
			query.collide_with_bodies = true
			query.collision_mask = 1 << 0  # terrain layer
			var result = get_world_3d().direct_space_state.intersect_ray(query)
			if result and result.has("position"):
				y = result.position.y
			else:
				y -= 2.0  # fallback correction

			var obj: Node3D
			var picked_scene: PackedScene

			if not micro_data.has(pos_key):
				picked_scene = micro_scenes.pick_random()
				obj = picked_scene.instantiate()
				obj.rotation.y = randf_range(0.0, TAU)
				#obj.position = Vector3(wx, y - 0.5, wz)
				# inside _spawn_micro_objects_for_chunk
				var local_x = wx - world_origin.x
				var local_z = wz - world_origin.y
				obj.position = Vector3(local_x, y - 1.0, local_z)

				chunk.add_child(obj, true)
				objects.append(obj)

				micro_data[pos_key] = {
					"picked_scene": picked_scene,
					"rotation": obj.rotation,
					"custom": {"was_reached": false}
				}
			else:
				var data = micro_data[pos_key]
				picked_scene = data.picked_scene
				obj = picked_scene.instantiate()
				obj.position = Vector3(wx, y - 0.5, wz)
				obj.rotation = data.rotation

				chunk.add_child(obj, true)
				objects.append(obj)

	_spawned_micro_objects[chunk_pos] = objects
