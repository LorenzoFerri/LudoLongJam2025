extends Node3D

@export var speed: float = 300.0

@export var start_position: Vector3
@export var end_position: Vector3

func _ready() -> void:
	self.global_position = start_position
	self.look_at(end_position)


func _process(delta: float) -> void:
	global_position = global_position.move_toward(end_position, delta * speed)
	if global_position.distance_to(end_position) <= 0.1:
		visible = false
		queue_free()
	
	
