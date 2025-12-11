extends CharacterBody3D
class_name Zombie

var damage_number_scene = preload("res://Scenes/Particles/DamageNumber.tscn")

var blood_decal = preload("res://Assets/Decal/Blood.png")
const ZombieManagerClass := preload("res://Scenes/Enemies/Zombie/ZombieManager.gd")
@export var gravity_scale := 10.0
@export var walk_animation_name := "walk"
@export var money_gain_on_kill := 10.0
@export var fuel_loss_on_hit := PlayerState.STARTING_FUEL / 10

@onready var physical_bone_simulator_3d: PhysicalBoneSimulator3D = $rig_CharRoot005/Object_245/Skeleton3D/PhysicalBoneSimulator3D
@onready var collision_shape_3d: CollisionShape3D = $MainCollisionShape
@export_node_path var target_path: NodePath
@export_range(0.1, 10.0, 0.1) var speed := 3.0
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@export var dead = false
const blood_emitter_scene = preload("res://Scenes/Particles/BloodEmitter.tscn")
var time_accum = 0.0
@onready var health_component: HealthComponent = $HealthComponent
@onready var hurt_box_component: HurtBoxComponent = $HurtBoxComponent
var _move_direction := Vector3.ZERO
var _vertical_velocity := 0.0
var _is_on_floor := false
@onready var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity") * gravity_scale

func _ready() -> void:
	call_deferred("_randomize_walk_animation")
	if ZombieManagerClass.instance:
		ZombieManagerClass.instance.register_zombie(self)
	else:
		call_deferred("_deferred_register")

func _deferred_register() -> void:
	if ZombieManagerClass.instance:
		ZombieManagerClass.instance.register_zombie(self)
	else:
		push_warning("ZombieManager instance not available for registration")

func _exit_tree() -> void:
	if ZombieManagerClass.instance:
		ZombieManagerClass.instance.unregister_zombie(self)

func _on_hurt_box_component_hurt(_weapon: Weapon, hit_position: Vector3, hit_normal: Vector3, damage: float) -> void:
	spawn_blood(hit_position, hit_normal)
	var damage_number = damage_number_scene.instantiate()
	damage_number.damage = damage
	get_parent().add_child(damage_number)
	damage_number.global_position = hit_position

func manager_apply_transform(new_transform: Transform3D, direction: Vector3, vertical_velocity: float, on_floor: bool) -> void:
	global_transform = new_transform
	_move_direction = direction
	_vertical_velocity = vertical_velocity
	_is_on_floor = on_floor
	velocity = Vector3(direction.x * speed, vertical_velocity, direction.z * speed)

func manager_get_vertical_velocity() -> float:
	return _vertical_velocity

func manager_set_vertical_velocity(value: float) -> void:
	_vertical_velocity = value

func manager_is_on_floor() -> bool:
	return _is_on_floor

func manager_set_on_floor(value: bool) -> void:
	_is_on_floor = value

func manager_get_gravity() -> float:
	return _gravity

func manager_get_move_direction() -> Vector3:
	return _move_direction

func _randomize_walk_animation() -> void:
	if animation_player == null:
		return
	var anim_name := animation_player.current_animation
	if anim_name == "" and walk_animation_name != "":
		anim_name = walk_animation_name
		if anim_name != "":
			animation_player.play(anim_name)
	if anim_name == "":
		return
	var animation: Animation = animation_player.get_animation(anim_name)
	if animation == null:
		return
	var length: float = animation.length
	if length <= 0.0:
		return
	var offset: float = randf() * length
	animation_player.seek(offset, true)

func spawn_blood(hit_position: Vector3, hit_normal: Vector3):
	var blood_emitter = blood_emitter_scene.instantiate()
	blood_emitter.position = hit_position
	blood_emitter.look_at_from_position(hit_position, hit_position - hit_normal, Vector3.UP)
	blood_emitter.emitting = true
	get_parent().add_child(blood_emitter)
	
	var decal = Decal.new()
	decal.top_level = true
	decal.texture_albedo = blood_decal
	decal.texture_orm = blood_decal
	decal.position = hit_position
	decal.cull_mask = 0b1000
	decal.rotate_y(randf_range(0, 2 * PI))
	decal.modulate = Color("#c40000")
	var random_scale = randf_range(0.5, 2)
	decal.scale = Vector3(random_scale, random_scale, random_scale)
	decal.tree_entered.connect(func():
		await get_tree().create_timer(5).timeout
		var color = decal.modulate
		color.a = 0
		var tween = get_tree().create_tween()
		tween.tween_property(decal, "modulate", color, 5)
		tween.tween_callback(decal.queue_free)
	)
	get_parent().add_child(decal)

@rpc("authority", "call_local")
func die():
	dead = true
	animation_player.active = false
	collision_shape_3d.set_deferred("disabled", true)
	physical_bone_simulator_3d.set_deferred("active", true)
	physical_bone_simulator_3d.call_deferred("physical_bones_start_simulation")
	
	if multiplayer.is_server():
		PlayerState.money += money_gain_on_kill
	# if ZombieManagerClass.instance:
	# 	ZombieManagerClass.instance.unregister_zombie(self)

func _on_health_component_death() -> void:
	die.rpc()


func _on_hurt_box_component_body_entered(body: Node3D) -> void:
	if body is Truck:
		var truck: Truck = body
		hurt_box_component.hit.rpc(
			WeaponList.WeaponType.TRUCK,
			truck.global_transform.origin,
			truck.global_position.direction_to(global_transform.origin),
			100000
		)
		
		var fuel_loss = fuel_loss_on_hit
		var fuel_loss_upgrades = PlayerState.get_active_effects_by_type("ArmorModifier")
		if fuel_loss_upgrades.size() != 0:
			fuel_loss -= max(fuel_loss_upgrades.reduce(func(acc, e): return acc + e.flatValue, 0.0), 0)
			fuel_loss *= max(1 - fuel_loss_upgrades.reduce(func(acc, e): return acc + e.percentageValue, 0.0) / 100, 0)
		
		PlayerState.fuel -= max(fuel_loss, fuel_loss_on_hit * 0.25)


var can_be_hit_by_fire_trail = true
func hit_by_fire_trail(damage: float):
	if not can_be_hit_by_fire_trail:
		return
	
	can_be_hit_by_fire_trail = false
	get_tree().create_timer(1).timeout.connect(func(): can_be_hit_by_fire_trail = true)
	hurt_box_component.hit.rpc(WeaponList.WeaponType.MACHINE_GUN, global_position, Vector3.UP, damage)
