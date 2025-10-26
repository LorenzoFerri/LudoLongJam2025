extends VehicleBody3D

@export var MAX_RPM := 450
@export var MAX_TORQUE := 300
@export var TURN_SPEED := 3
@export var TURN_AMOUNT := 0.4

@onready var rear_left_wheel: VehicleWheel3D = $RearLeftWheel
@onready var rear_right_wheel: VehicleWheel3D = $RearRightWheel
@onready var camera_arm: SpringArm3D = $CameraArm
@onready var rear_left_gpu_particles: GPUParticles3D = $RearLeftGPUParticles

@export var network_transform: Transform3D
@export var network_quaternion: Quaternion

func _ready() -> void:
	if multiplayer.get_unique_id() != MultiplayerManager.get_driver_id():
		# freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		freeze = true

func _process(delta: float) -> void:
	camera_arm.position = camera_arm.position.move_toward(position + Vector3.UP * 2, delta * 100)
	var RPM_left = abs(rear_left_wheel.get_rpm())
	var RPM_right = abs(rear_right_wheel.get_rpm())
	
	if multiplayer.get_unique_id() == MultiplayerManager.get_driver_id():
		var direction =  Input.get_action_strength("brake") - Input.get_action_strength("accelerate")
		var steering_direction = Input.get_action_strength("steer_left") - Input.get_action_strength("steer_right")

		var current_rpm = (RPM_left + RPM_right) / 2
		var torque = direction * MAX_TORQUE * (1 - (current_rpm / MAX_RPM))
		engine_force = torque
		steering = lerp(steering, steering_direction * TURN_AMOUNT, TURN_SPEED * delta)

		if direction == 0: brake = 2
		network_transform = global_transform
		network_quaternion = quaternion
	else:
		# global_transform = network_transform
		# quaternion = network_quaternion
		global_transform = global_transform.interpolate_with(network_transform, 0.1)
		quaternion = quaternion.slerp(network_quaternion, 0.1)

	rear_left_gpu_particles.emitting = rear_left_wheel.is_in_contact() and (brake > 0 or engine_force < 0) and RPM_left > 5
