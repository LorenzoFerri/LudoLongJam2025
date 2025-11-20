extends Node3D

class_name Goal

signal goal_interacted

var was_reached: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.rotate_y(deg_to_rad(randi_range(0, 360)))

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Truck and not was_reached:
		body.toggle_goal_interact_button(true)

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body is Truck and not was_reached:
		body.toggle_goal_interact_button(false)

func interact():
	goal_interacted.emit()
