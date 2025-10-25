extends SpringArm3D

@export var CAMERA_SENSITIVITY := 10

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(delta: float) -> void:
	rotation_degrees.x = clamp(rotation_degrees.x - Input.get_axis("camera_up", "camera_down") * CAMERA_SENSITIVITY * delta, -90, -10)
	rotation_degrees.y -= Input.get_axis("camera_left", "camera_right") * CAMERA_SENSITIVITY * delta

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation_degrees.x = clamp(rotation_degrees.x - event.relative.y * CAMERA_SENSITIVITY * 0.01, -90, -10)
		rotation_degrees.y -= event.relative.x * CAMERA_SENSITIVITY * 0.01
