extends VehicleBody3D

class_name Truck

@export var MAX_ENGINE_FORCE: float = 2000.0
@export var MAX_BRAKE_FORCE: float = 100.0
@export var REVERSE_FORCE: float = 400.0
@export var REVERSE_THRESHOLD: float = 0.5
@export var MAX_RPM := 450
@export var MAX_TORQUE := 300
@export var TURN_SPEED := 3
@export var TURN_AMOUNT := 0.4
@export var MAX_SPEED_MPS = 50 / 3.6

@onready var rear_left_wheel: VehicleWheel3D = $RearLeftWheel
@onready var rear_right_wheel: VehicleWheel3D = $RearRightWheel
@onready var camera_arm: SpringArm3D = $CameraArm
@onready var camera: Camera3D = $CameraArm/Camera3D
@onready var weapon: Node3D = $Weapon
@onready var weapon_position: Marker3D = $WeaponPosition
@onready var rear_left_gpu_particles: GPUParticles3D = $RearLeftGPUParticles

@onready var score_label: Label = %ScoreLabel
@onready var fuel_bar: ProgressBar = $CanvasLayer/FuelBar
@onready var shop_label: Label = %ShopLabel
@onready var shop: ShopUI = $CanvasLayer/Shop

@onready var goal_arrow: MeshInstance3D = %GoalArrow

var inside_goal: Goal = null

var next_goal_position: Vector3 = Vector3.ZERO

func _ready() -> void:
	MultiplayerManager.players_changed.connect(_on_players_changed)
	
	_on_players_changed()

func _on_players_changed() -> void:
	set_multiplayer_authority(MultiplayerManager.get_driver_id())
	weapon.set_multiplayer_authority(MultiplayerManager.get_shooter_id())

func toggle_goal_interact_button(make_visible: bool):
	shop_label.visible = make_visible

func _process(delta: float) -> void:
	camera_arm.position = camera_arm.position.move_toward(position + Vector3.UP * 2, delta * 100)
	
	if shop.visible:
		return
	
	weapon.position = weapon_position.global_position
	weapon.rotation = weapon_position.global_rotation
	weapon.rotate_object_local(Vector3.UP, -global_rotation.y)
	var RPM_left = abs(rear_left_wheel.get_rpm())
	var RPM_right = abs(rear_right_wheel.get_rpm())
	
	fuel_bar.value = PlayerState.fuel
	fuel_bar.max_value = PlayerState.max_fuel
	score_label.text = str(PlayerState.money)
	
	var current_speed = linear_velocity.dot(-global_transform.basis.z)
	if multiplayer.is_server():
		PlayerState.current_speed = current_speed
	
	if multiplayer.get_unique_id() == MultiplayerManager.get_driver_id():
		camera.current = true
		
		var throttle_input = Input.get_action_strength("accelerate")
		var brake_input = Input.get_action_strength("brake")
		var steering_direction = Input.get_action_strength("steer_left") - Input.get_action_strength("steer_right")

		var current_max_speed = MAX_SPEED_MPS
		var speed_upgrades = PlayerState.get_active_effects_by_type("SpeedModifier")
		if speed_upgrades.size() != 0:
			var flatValue = speed_upgrades.reduce(func(acc, e): return acc + e.flatValue, 0.0)
			if current_max_speed > 0:
				current_max_speed += flatValue
			else:
				current_max_speed -= flatValue
			current_max_speed *= 1 + speed_upgrades.reduce(func(acc, e): return acc + e.percentageValue, 0.0) / 100
		

		# %Speed.text = str(floor(current_speed)) + "/" + str(current_max_speed)
		%Speed.text = "%5.2f/%5.2f km/h" % [current_speed * 3.6, current_max_speed * 3.6]
		
		engine_force = 0
		brake = 0

		if throttle_input > 0.0:
			if current_speed < current_max_speed:
				var speed_factor = 1.0 - (current_speed / current_max_speed)
				var force = -MAX_ENGINE_FORCE * throttle_input * clamp(speed_factor, 0.0, 1.0)
				engine_force = force
			else:
				engine_force = 0
		
		if brake_input > 0.0:
			if current_speed > REVERSE_THRESHOLD:
				brake = MAX_BRAKE_FORCE * brake_input
				engine_force = 0
			else:
				if abs(current_speed) < current_max_speed:
					var speed_factor = 1.0 - (abs(current_speed) / current_max_speed)
					var force = MAX_ENGINE_FORCE * brake_input * clamp(speed_factor, 0.0, 1.0)
					engine_force = force
				else:
					engine_force = 0

		PlayerState.engine_force = engine_force
		
		steering = lerp(steering, steering_direction * TURN_AMOUNT, TURN_SPEED * delta)

		if throttle_input == 0 and brake_input == 0: brake = 2.0
		
		if next_goal_position != Vector3.ZERO:
			var dir_world = (next_goal_position - global_position)
			dir_world.y = 0
			
			if dir_world.length() == 0:
				return
			dir_world = dir_world.normalized()

			var dir_local = global_transform.basis.inverse() * dir_world

			var target_yaw = atan2(dir_local.x, dir_local.z)

			goal_arrow.rotation.y = target_yaw
			
			goal_arrow.visible = true
			
		else:
			goal_arrow.visible = false
			

	rear_left_gpu_particles.emitting = rear_left_wheel.is_in_contact() and (brake > 0 or PlayerState.engine_force < 0) and RPM_left > 5

	if multiplayer.is_server():
		PlayerState.fuel -= abs(engine_force) * PlayerState.fuel_decay_rate * delta
		

	if Input.is_action_just_pressed("switch_roles"):
		for player_id in MultiplayerManager.players.keys():
			if MultiplayerManager.players[player_id] == MultiplayerManager.Role.DRIVER:
				MultiplayerManager.set_player_role.rpc(player_id, MultiplayerManager.Role.SHOOTER)
			else:
				MultiplayerManager.set_player_role.rpc(player_id, MultiplayerManager.Role.DRIVER)

	if Input.is_action_pressed("interact") and shop_label.visible and inside_goal:
		toggle_goal_interact_button(false)
		inside_goal.interact()
		shop.show_shop()
