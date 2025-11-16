extends Node3D

@onready var marker: Marker3D = $Marker3D
@onready var zombie_scene: PackedScene = preload("res://Scenes/Enemies/Zombie/Zombie.tscn")
@onready var truck: Node3D = $Truck
@onready var zombies = %Zombies
const ZombieManagerClass := preload("res://Scenes/Enemies/Zombie/ZombieManager.gd")

var players_loaded: int = 0

func _ready() -> void:
	# truck.set_multiplayer_authority(MultiplayerManager.get_driver_id())
	if ZombieManagerClass.instance == null:
		var manager := ZombieManagerClass.new()
		manager.name = "ZombieManager"
		add_child(manager)
	MultiplayerManager.player_loaded.connect(_on_player_loaded)
	MultiplayerManager.scene_loaded.rpc()

func _on_player_loaded() -> void:
	if multiplayer.is_server():
		players_loaded += 1
		if players_loaded >= MultiplayerManager.players.size():
			start_game()
			if players_loaded == 1:
				MultiplayerManager.set_player_role(1, MultiplayerManager.Role.SHOOTER)

func start_game() -> void:
	pass
	#for i in range(100):
		#var zombie_instance = zombie_scene.instantiate()
		#zombie_instance.target_path = truck.get_path()
		#zombies.add_child(zombie_instance, true)
		#zombie_instance.global_transform.origin = Vector3(
			#randf_range(-20, 20),
			#0,
			#randf_range(-20, 20)
		#) + marker.position
