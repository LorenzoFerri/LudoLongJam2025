extends Node3D

@export var speed: float = 300.0

@export var start_position: Vector3
@export var end_position: Vector3
@onready var multiplayer_synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer
# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	if start_position == Vector3.ZERO and end_position == Vector3.ZERO:
		return
	set_multiplayer_authority(MultiplayerManager.get_shooter_id())
	multiplayer_synchronizer.set_multiplayer_authority(MultiplayerManager.get_shooter_id())
	self.global_position = start_position
	self.look_at(end_position)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if start_position == Vector3.ZERO and end_position == Vector3.ZERO:
		return
	
	global_position = global_position.move_toward(end_position, delta * speed)
	
	if global_position.distance_to(end_position) <= 0.1:
		visible = false
		await get_tree().create_timer(5.0).timeout
		# queue_free()
	
	
