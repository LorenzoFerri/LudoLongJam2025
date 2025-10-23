extends SpringArm3D

@export var CAMERA_SENSITIVITY := 100

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rotation_degrees.x = clamp(rotation_degrees.x - Input.get_axis("camera_up", "camera_down") * CAMERA_SENSITIVITY * delta, -90, -10)
	rotation_degrees.y -= Input.get_axis("camera_left", "camera_right") * CAMERA_SENSITIVITY * delta
