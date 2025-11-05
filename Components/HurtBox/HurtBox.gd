extends Area3D

class_name HurtBoxComponent

signal hurt(weapon: Weapon, hit_position: Vector3, hit_normal: Vector3)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

@rpc("any_peer", "call_local", "reliable")
func hit(weapon_type: Weapon.WeaponType, hit_position: Vector3, hit_normal: Vector3) -> void:
	hurt.emit(Weapon.weapons[weapon_type], hit_position, hit_normal)
