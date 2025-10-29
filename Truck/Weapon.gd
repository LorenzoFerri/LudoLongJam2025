extends Node3D

@onready var x_rotation_control = $Rotate_Z/Rotate_X
@onready var z_rotation_control = $Rotate_Z
# @onready var camera_arm: SpringArm3D = $CameraArm
@onready var camera : Camera3D = %Camera3D
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if multiplayer.get_unique_id() == MultiplayerManager.get_driver_id(): return
	camera.current = true
	# camera.position = camera.position.move_toward(global_position + Vector3.UP, delta * 100)
	var horizontal_input = Input.get_action_strength("camera_left") - Input.get_action_strength("camera_right")
	var vertical_input = Input.get_action_strength("camera_down") - Input.get_action_strength("camera_up")
	x_rotation_control.rotation_degrees.x = clamp(x_rotation_control.rotation_degrees.x + vertical_input * 50 * delta, -45, 45)
	z_rotation_control.rotation_degrees.y += horizontal_input * 100 * delta

func _input(event: InputEvent) -> void:
	if multiplayer.get_unique_id() == MultiplayerManager.get_driver_id(): return
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		x_rotation_control.rotation_degrees.x = clamp(x_rotation_control.rotation_degrees.x + event.relative.y * 0.1, -45, 45)
		z_rotation_control.rotation_degrees.y -= event.relative.x * 0.1	
