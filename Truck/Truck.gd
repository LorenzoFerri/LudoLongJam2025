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
@onready var rear_left_gpu_particles: GPUParticles3D = $RearLeftGPUParticles

@onready var goal_arrow: MeshInstance3D = %GoalArrow

var next_goal: Goal = null

func _ready() -> void:
	MultiplayerManager.players_changed.connect(_on_players_changed)
	_on_players_changed()

func _on_players_changed() -> void:
	for player_id in MultiplayerManager.players.keys():
		if MultiplayerManager.players[player_id] == MultiplayerManager.Role.DRIVER:
			set_multiplayer_authority(player_id)
		else:
			weapon.set_multiplayer_authority(player_id)


func _process(delta: float) -> void:
	camera_arm.position = camera_arm.position.move_toward(position + Vector3.UP * 2, delta * 100)
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

		if direction == 0: brake = 2
		
		# goal arrow
		if next_goal != null:
			# Direction from car to goal, in world space
			var dir_world = (next_goal.global_position - global_position)
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
