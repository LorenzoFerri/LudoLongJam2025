extends Node3D
class_name ZombieManager

var zombie_scene = preload("res://Scenes/Enemies/Zombie/Zombie.tscn")

@export_range(0, 512, 1) var collisions_per_frame := 0
@export var collision_margin := 0.05

@export var min_zombie_spawn_distance := 50.0
@export var max_zombie_spawn_distance := 150.0

@export var spawn_rate_curve: Curve
@export var spawn_cooldown_curve: Curve

@export var big_zombie_spawn_curve: Curve

var zombie_spawn_cooldown := 0.0

@export var player: Node3D

@export var zombie_play_sound_chance := 0.0005

static var instance: ZombieManager

var _zombies: Array[Zombie] = []
var _next_index: int = 0

var elapsed_time := 0.0

func _ready() -> void:
	if instance and instance != self:
		push_warning("ZombieManager instance already exists, removing duplicate")
		self.queue_free()
		return
	instance = self
	set_physics_process(true)

func _exit_tree() -> void:
	if instance == self:
		instance = null

func register_zombie(zombie: Zombie) -> void:
	if zombie in _zombies:
		return
	_zombies.append(zombie)
	zombie.set_physics_process(false)
	zombie.manager_set_vertical_velocity(0.0)
	zombie.manager_set_on_floor(false)

func unregister_zombie(zombie: Zombie) -> void:
	var idx := _zombies.find(zombie)
	if idx == -1:
		return
	_zombies.remove_at(idx)
	if _next_index > idx:
		_next_index -= 1
	_next_index = clamp(_next_index, 0, max(0, _zombies.size() - 1))

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	elapsed_time += delta
	zombie_spawn_cooldown -= delta
	
	var max_zombies = spawn_rate_curve.sample(elapsed_time / 60)
	if _zombies.size() < max_zombies:
		if zombie_spawn_cooldown <= 0:
			spawn_zombie()
			zombie_spawn_cooldown = spawn_cooldown_curve.sample(elapsed_time / 60)
	
	if _zombies.is_empty():
		return
	var total: int = _zombies.size()
	var limit: int
	if collisions_per_frame <= 0:
		limit = total
	else:
		limit = min(collisions_per_frame, total)
	for i in range(total - 1, -1, -1):
		var index := (_next_index + i) % total
		var zombie: Zombie = _zombies.get(index)
		if zombie == null:
			continue
		var run_collision := i < limit
		var vertical_speed: float = zombie.manager_get_vertical_velocity()
		var needs_collision: bool = run_collision or (not zombie.manager_is_on_floor()) or (absf(vertical_speed) > 0.01)
		_update_zombie(zombie, delta, needs_collision)
	_next_index = (_next_index + limit) % max(1, total)

func _update_zombie(zombie: Zombie, delta: float, perform_collision: bool) -> void:
	if zombie.dead:
		unregister_zombie(zombie)
		zombie.queue_free()
	if not zombie.is_inside_tree():
		return
	if zombie.position.distance_to(player.position) > max_zombie_spawn_distance * 1.5:
		unregister_zombie(zombie)
		zombie.queue_free()
	var origin: Vector3 = zombie.global_transform.origin
	var dir: Vector3 = zombie.manager_get_move_direction()
	if player != null:
		var target_pos: Vector3 = player.global_transform.origin
		var to_target: Vector3 = target_pos - origin
		to_target.y = 0.0
		var dist_sq: float = to_target.length_squared()
		if dist_sq >= 0.0001:
			dir = to_target / sqrt(dist_sq)
	var gravity_force: float = zombie.manager_get_gravity()
	var vertical_velocity: float = zombie.manager_get_vertical_velocity()
	var was_on_floor := zombie.manager_is_on_floor()
	# if was_on_floor:
	# 	if vertical_velocity < 0.0:
	# 		vertical_velocity = 0.0
	# else:
	vertical_velocity -= gravity_force * delta
	var horizontal_velocity: Vector3 = dir * zombie.speed
	var velocity: Vector3 = Vector3(horizontal_velocity.x, vertical_velocity, horizontal_velocity.z)
	var motion: Vector3 = velocity * delta
	if was_on_floor and vertical_velocity <= 0.0:
		motion.y = 0.0
	if motion.length_squared() == 0.0:
		zombie.manager_apply_transform(zombie.global_transform, dir, vertical_velocity, zombie.manager_is_on_floor())
		return
	var new_transform: Transform3D = zombie.global_transform
	var on_floor := was_on_floor
	if perform_collision:
		var params: PhysicsTestMotionParameters3D = PhysicsTestMotionParameters3D.new()
		params.from = zombie.global_transform
		params.motion = motion
		params.margin = collision_margin
		var result: PhysicsTestMotionResult3D = PhysicsTestMotionResult3D.new()
		var collided: bool = PhysicsServer3D.body_test_motion(zombie.get_rid(), params, result)
		var travel: Vector3 = motion
		if collided:
			travel = result.get_travel()
			var collision_count := result.get_collision_count()
			for j in range(collision_count):
				var normal: Vector3 = result.get_collision_normal(j)
				if normal.dot(Vector3.UP) > 0.6:
					on_floor = true
					break
			if on_floor and vertical_velocity < 0.0:
				vertical_velocity = 0.0
		else:
			if vertical_velocity < 0.0:
				on_floor = false
		new_transform.origin += travel
	else:
		new_transform.origin += motion
		on_floor = false
	if dir.length_squared() > 0.0001:
		new_transform = new_transform.looking_at(new_transform.origin + dir, Vector3.UP)
	PhysicsServer3D.body_set_state(zombie.get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, new_transform)
	zombie.manager_apply_transform(new_transform, dir, vertical_velocity, on_floor)

	if randf() <= zombie_play_sound_chance:
		zombie.play_zombie_sound()

func spawn_zombie():
	var zombie: Zombie = zombie_scene.instantiate()
	zombie.position = get_random_point_within_radius(randf_range(min_zombie_spawn_distance, max_zombie_spawn_distance))	
	
	var big_zombie_chance = big_zombie_spawn_curve.sample(elapsed_time / 60)
	var is_big_zombie = randf() < big_zombie_chance
	
	if is_big_zombie:
		zombie.scale = Vector3(4, 4, 4)
	
	add_child(zombie, true)
	
	if is_big_zombie:
		zombie.fuel_loss_on_hit *= 3
		zombie.health_component.max_hp *= 3
		zombie.health_component.hp *= 3
		zombie.money_gain_on_kill += 5

# Function to pick a random point within a radius around this node
func get_random_point_within_radius(radius: float = 20.0) -> Vector3:
	# Pick a random direction on the XZ plane
	var angle = randf() * TAU
	var offset = Vector3(cos(angle) * radius, 0, sin(angle) * radius)
	
	var result_position = player.global_position + offset
	
	# precise terrain surface using raycast
	var start = Vector3(result_position.x, result_position.y + 200.0, result_position.z)
	var end = Vector3(result_position.x, result_position.y - 500.0, result_position.z)
	var query = PhysicsRayQueryParameters3D.create(start, end)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = 1 << 0  # terrain layer
	var result = get_world_3d().direct_space_state.intersect_ray(query)
	if result and result.has("position"):
		result_position.y = result.position.y
	else:
		result_position.y -= 2.0  # fallback correction
	
	return result_position
