extends Node3D

class_name Package

signal picked_up

@export var speed: float = 1.2
@export var bob_height: float = 0.1      # how high/low it moves
@export var bob_speed: float = 2       # how fast it bobs

@export var score_gain: float = 1000.0

var was_taken = false

var base_y: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	base_y = global_transform.origin.y


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rotate_y(speed * delta)
	
	
	# Up and down bobbing
	var new_y = base_y + sin(Time.get_ticks_msec() * 0.001 * bob_speed) * bob_height
	
	# Apply bobbing
	global_transform.origin.y = new_y


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Truck and not was_taken:
		was_taken = true
		if multiplayer.is_server():
			PlayerState.money += score_gain
		body.play_money_sound()
		picked_up.emit()
