extends Node3D

@onready var marker: Marker3D = $Marker3D
@onready var zombie_scene: PackedScene = preload("res://Zombie/Zombie.tscn")
@onready var truck: Node3D = $Truck

var players_loaded: int = 0

func _ready() -> void:
	MultiplayerManager.scene_loaded.rpc()
	MultiplayerManager.player_loaded.connect(_on_player_loaded)

func _on_player_loaded() -> void:
	if multiplayer.is_server():
		players_loaded += 1
		if players_loaded >= MultiplayerManager.players.size():
			start_game.rpc()

@rpc("call_local")
func start_game() -> void:
	for i in range(10):
		var zombie_instance = zombie_scene.instantiate()
		zombie_instance.target = truck
		add_child(zombie_instance)
		zombie_instance.global_transform.origin = Vector3(
			randf_range(-5, 5),
			0,
			randf_range(-5, 5)
		) + marker.position