extends Node

class_name HealthComponent

signal health_changed(old_value: float, new_value: float)
signal death

@export var hurtbox_component: HurtBoxComponent
@export var hp := 3.0:
	set(value):
		var new_hp = clamp(value, 0, max_hp)
		health_changed.emit(hp, new_hp)
		hp = new_hp
		
		if hp <= 0: death.emit()
		
@export var max_hp := 3.0:
	set(value):
		max_hp = value
		hp = clamp(hp, 0, max_hp)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hurtbox_component.hurt.connect(take_damage)

func take_damage(weapon: Weapon, _hit_position: Vector3, _hit_normal: Vector3):
	if multiplayer.is_server():
		hp -= weapon.damage
