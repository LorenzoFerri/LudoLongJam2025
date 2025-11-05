extends Resource

class_name Weapon

@export var damage: float = 1.0
@export var attack_cooldown: float = 0.5
@export var projectile_speed: int = 200
@export var weapon_type: WeaponType = WeaponType.MACHINE_GUN

enum WeaponType {
	MACHINE_GUN
}

static var weapons = {
	WeaponType.MACHINE_GUN: preload("res://Weapon/MachineGun.tres")
}
