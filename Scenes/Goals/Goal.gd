extends Node3D

class_name Goal

signal goal_reached

var can_be_reached: bool = false
var was_reached: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.rotate_y(deg_to_rad(randi_range(0, 360)))

func _on_area_3d_body_entered(body: Node3D) -> void:
	if can_be_reached and body is Truck and not was_reached:
		goal_reached.emit()
