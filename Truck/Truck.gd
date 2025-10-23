extends VehicleBody3D

@export var MAX_RPM := 450
@export var MAX_TORQUE := 300
@export var TURN_SPEED := 3
@export var TURN_AMOUNT := 0.4

@onready var rear_left_wheel: VehicleWheel3D = $RearLeftWheel
@onready var rear_right_wheel: VehicleWheel3D = $RearRightWheel
@onready var camera_arm: SpringArm3D = $CameraArm
@onready var rear_left_gpu_particles: GPUParticles3D = $RearLeftGPUParticles

func _process(delta: float) -> void:
	camera_arm.position = position + Vector3.UP * 2
	var direction =  Input.get_action_strength("brake") - Input.get_action_strength("accelerate")
	var steering_direction = Input.get_action_strength("steer_left") - Input.get_action_strength("steer_right")
	var RPM_left = abs(rear_left_wheel.get_rpm())
	var RPM_right = abs(rear_right_wheel.get_rpm())
	var current_rpm = (RPM_left + RPM_right) / 2
	var torque = direction * MAX_TORQUE * (1 - (current_rpm / MAX_RPM))
	
	engine_force = torque
	steering = lerp(steering, steering_direction * TURN_AMOUNT, TURN_SPEED * delta)

	if direction == 0: brake = 2

	rear_left_gpu_particles.emitting = rear_left_wheel.is_in_contact() and (brake > 0 or engine_force < 0) and RPM_left > 5
