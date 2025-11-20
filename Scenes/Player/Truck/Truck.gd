extends VehicleBody3D

class_name Truck

@export var MAX_RPM := 450
@export var MAX_TORQUE := 300
@export var TURN_SPEED := 3
@export var TURN_AMOUNT := 0.4

@onready var rear_left_wheel: VehicleWheel3D = $RearLeftWheel
@onready var rear_right_wheel: VehicleWheel3D = $RearRightWheel
@onready var camera_arm: SpringArm3D = $CameraArm
@onready var camera : Camera3D = $CameraArm/Camera3D
@onready var weapon: Node3D = $Weapon
@onready var weapon_position: Marker3D = $WeaponPosition
@onready var rear_left_gpu_particles: GPUParticles3D = $RearLeftGPUParticles

@onready var score_label: Label = %ScoreLabel
@onready var fuel_bar: ProgressBar = $CanvasLayer/FuelBar
@onready var shop_label: Label = %ShopLabel


@export var STARTING_FUEL := 25000.0

@export var fuel: float = STARTING_FUEL:
	set(value):
		fuel = clamp(value, 0, max_fuel)
		fuel_bar.value = value
@export var max_fuel: float = STARTING_FUEL:
	set(value):
		max_fuel = value
		fuel = clamp(fuel, 0, max_fuel)
		fuel_bar.max_value = max_fuel
@export var fuel_decay_rate := 1.0

var current_score := 0.0:
	set(value):
		current_score = value
		score_label.text = str(value)

var money := 0.0

@onready var goal_arrow: MeshInstance3D = %GoalArrow

var next_goal_position: Vector3 = Vector3.ZERO

func _ready() -> void:
	MultiplayerManager.players_changed.connect(_on_players_changed)
	
	fuel = STARTING_FUEL
	max_fuel = STARTING_FUEL
	
	_on_players_changed()

func _on_players_changed() -> void:
	set_multiplayer_authority(MultiplayerManager.get_driver_id())
	weapon.set_multiplayer_authority(MultiplayerManager.get_shooter_id())


func toggle_goal_interact_button(make_visible: bool):
	shop_label.visible = make_visible


func _process(delta: float) -> void:
	camera_arm.position = camera_arm.position.move_toward(position + Vector3.UP * 2, delta * 100)
	weapon.position = weapon_position.global_position
	weapon.rotation = weapon_position.global_rotation
	weapon.rotate_object_local(Vector3.UP, -global_rotation.y)
	var RPM_left = abs(rear_left_wheel.get_rpm())
	var RPM_right = abs(rear_right_wheel.get_rpm())
	
	if multiplayer.get_unique_id() == MultiplayerManager.get_driver_id():
		camera.current = true
		var direction =  Input.get_action_strength("brake") - Input.get_action_strength("accelerate")
		var steering_direction = Input.get_action_strength("steer_left") - Input.get_action_strength("steer_right")

		var current_rpm = (RPM_left + RPM_right) / 2
		var torque = direction * MAX_TORQUE * (1 - (current_rpm / MAX_RPM))
		engine_force = torque
		steering = lerp(steering, steering_direction * TURN_AMOUNT, TURN_SPEED * delta)

		fuel -= abs(engine_force) * fuel_decay_rate * delta

		if direction == 0: brake = 2
		
		# goal arrow
		if next_goal_position != Vector3.ZERO:
			# Direction from car to goal, in world space
			var dir_world = (next_goal_position - global_position)
			dir_world.y = 0  # Ignore vertical difference

			if dir_world.length() == 0:
				return
			dir_world = dir_world.normalized()

			# Convert direction into the car’s local space
			var dir_local = global_transform.basis.inverse() * dir_world

			# Compute the yaw angle (rotation around Y)
			var target_yaw = atan2(dir_local.x, dir_local.z)

			# Rotate the arrow (in local space)
			goal_arrow.rotation.y = target_yaw
			
			goal_arrow.visible = true
			
	else:
		# da decidere
		goal_arrow.visible = false
		

	rear_left_gpu_particles.emitting = rear_left_wheel.is_in_contact() and (brake > 0 or engine_force < 0) and RPM_left > 5

	if Input.is_action_just_pressed("switch_roles"):
		for player_id in MultiplayerManager.players.keys():
			if MultiplayerManager.players[player_id] == MultiplayerManager.Role.DRIVER:
				MultiplayerManager.set_player_role.rpc(player_id, MultiplayerManager.Role.SHOOTER)
			else:
				MultiplayerManager.set_player_role.rpc(player_id, MultiplayerManager.Role.DRIVER)
