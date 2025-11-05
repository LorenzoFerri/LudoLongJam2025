extends Node

enum WeaponType {
	MACHINE_GUN,
	TRUCK
}

static var weapons = {
	WeaponType.MACHINE_GUN: preload("res://Weapon/MachineGun.tres"),
	WeaponType.TRUCK: preload("res://Weapon/Truck.tres")
}
