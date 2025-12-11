extends Node3D

@export var damage := 1.0
@export var time := 5.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().create_timer(time).timeout.connect(queue_free)

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Zombie:
		body.hit_by_fire_trail(damage)
