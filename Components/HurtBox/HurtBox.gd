extends Area3D

class_name HurtBoxComponent

signal hurt(weapon: Weapon, hit_position: Vector3, hit_normal: Vector3, damage: float)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

@rpc("any_peer", "call_local", "reliable")
func hit(weapon_type: WeaponList.WeaponType, hit_position: Vector3, hit_normal: Vector3, damage: float) -> void:
	hurt.emit(WeaponList.weapons[weapon_type], hit_position, hit_normal, damage)
