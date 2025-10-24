extends Node3D

@onready var marker: Marker3D = $Marker3D
@onready var zombie_scene: PackedScene = preload("res://Zombie/Zombie.tscn")
@onready var truck: Node3D = $Truck

func _ready() -> void:
	for i in range(10):
		var zombie_instance = zombie_scene.instantiate()
		zombie_instance.target = truck
		add_child(zombie_instance)
		zombie_instance.global_transform.origin = Vector3(
			randf_range(-5, 5),
			0,
			randf_range(-5, 5)
		) + marker.position
