extends MeshInstance3D

@export var speed: float = 100.0

@export var start_position: Vector3 = Vector3.ZERO
@export var end_position: Vector3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	assert(start_position != null, "Start position not set")
	assert(end_position != null, "End position not set")
	self.global_position = start_position
	self.look_at(end_position)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	global_position = global_position.move_toward(end_position, delta * speed)
	
	if global_position.distance_to(end_position) <= 0.1:
		queue_free()
	
	
