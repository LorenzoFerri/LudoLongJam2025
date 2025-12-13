extends Node3D

class_name Shooter

const bullet_scene = preload("res://Weapon/Projectiles/Bullet.tscn")
const explosion_scene = preload("res://Scenes/Particles/Explosion/Explosion.tscn")

const machine_gun = preload("res://Weapon/MachineGun.tres")

@onready var x_rotation_control = $Rotate_Z/Rotate_X
@onready var z_rotation_control = $Rotate_Z
# @onready var camera_arm: SpringArm3D = $CameraArm
@onready var camera: Camera3D = %Camera3D
# Called when the node enters the scene tree for the first time.
@onready var shooting_timer: Timer = $ShootingTimer
@onready var shooting_raycast: RayCast3D = %ShootingRaycast
@onready var bullets_group: Node3D = $Bullets
@onready var current_weapon: Weapon = machine_gun

@onready var shoot_sound: AudioStreamPlayer3D = $AudioStreamPlayer3D


func _ready() -> void:
	shooting_timer.wait_time = current_weapon.attack_cooldown

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if multiplayer.get_unique_id() != MultiplayerManager.get_shooter_id(): return
	camera.current = true
	# camera.position = camera.position.move_toward(global_position + Vector3.UP, delta * 100)
	var horizontal_input = Input.get_action_strength("camera_left") - Input.get_action_strength("camera_right")
	var vertical_input = Input.get_action_strength("camera_down") - Input.get_action_strength("camera_up")
	x_rotation_control.rotation_degrees.x = clamp(x_rotation_control.rotation_degrees.x + vertical_input * 50 * delta, -45, 45)
	z_rotation_control.rotation_degrees.y += horizontal_input * 100 * delta
	
	if Input.is_action_pressed("shoot") and shooting_timer.is_stopped():
		shooting_timer.start()
		shoot()

func _input(event: InputEvent) -> void:
	if multiplayer.get_unique_id() != MultiplayerManager.get_shooter_id(): return
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		x_rotation_control.rotation_degrees.x = clamp(x_rotation_control.rotation_degrees.x + event.relative.y * 0.1, -45, 45)
		z_rotation_control.rotation_degrees.y -= event.relative.x * 0.1

func shoot():
	spawn_bullet.rpc(shooting_raycast.global_position, shooting_raycast.to_global(shooting_raycast.target_position))
	if shooting_raycast.is_colliding():
		var collider = shooting_raycast.get_collider()
		if collider is HurtBoxComponent:
			var damage = current_weapon.damage
			var damage_upgrades = PlayerState.get_active_effects_by_type("DamageModifier")
			if damage_upgrades.size() != 0:
				damage += damage_upgrades.reduce(func(acc, e): return acc + e.flatValue, 0.0)
				damage *= 1 + damage_upgrades.reduce(func(acc, e): return acc + e.percentageValue, 0.0) / 100
			collider.hit.rpc(current_weapon.weapon_type, shooting_raycast.get_collision_point(), shooting_raycast.get_collision_normal(), damage)
		var explosion_upgrades = PlayerState.get_active_effects_by_type("ExplodingBullets")
		if explosion_upgrades.size() != 0:
			var explosion_damage = 0.0
			var explosion_radius = 0.0
			for upgrade in explosion_upgrades:
				explosion_damage += upgrade.damage
				explosion_radius += upgrade.radius
			spawn_explosion.rpc(shooting_raycast.get_collision_point(), explosion_radius, explosion_damage)

@rpc("any_peer", "call_local", "unreliable")
func spawn_bullet(start_position: Vector3, target_position: Vector3) -> void:
	if multiplayer.is_server():
		PlayerState.shot_number += 1
	
	var bullet: Node3D = bullet_scene.instantiate()
	bullet.start_position = start_position
	bullet.end_position = target_position
	bullet.speed = current_weapon.projectile_speed
	bullets_group.add_child(bullet)
	
	shoot_sound.pitch_scale = randf_range(1, 1.2)
	shoot_sound.play()

@rpc("any_peer", "call_local")
func spawn_explosion(explosion_position: Vector3, radius: float, damage: float) -> void:
	var explosion_instance: Node3D = explosion_scene.instantiate()
	explosion_instance.radius = radius
	explosion_instance.damage = damage
	bullets_group.add_child(explosion_instance)
	explosion_instance.global_position = explosion_position
