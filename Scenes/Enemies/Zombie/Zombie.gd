extends CharacterBody3D
class_name Zombie

var blood_decal = preload("res://Assets/Decal/Blood.png")

@onready var physical_bone_simulator_3d: PhysicalBoneSimulator3D = $rig_CharRoot005/Object_245/Skeleton3D/PhysicalBoneSimulator3D
@onready var collision_shape_3d: CollisionShape3D = $MainCollisionShape
@export_node_path var target_path: NodePath
var target: Node3D
@export_range(0.1, 10.0, 0.1) var speed := 3.0
var GRAVITY = ProjectSettings.get_setting("physics/3d/default_gravity") * 10
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@export var dead = false
const blood_emitter_scene = preload("res://Scenes/Particles/BloodEmitter.tscn")
var time_accum = 0.0
@onready var health_component: HealthComponent = $HealthComponent
@onready var hurt_box_component: HurtBoxComponent = $HurtBoxComponent

func _ready() -> void:
	target = get_node_or_null(target_path)

func _physics_process(delta):
	if dead: return
	if multiplayer.is_server():
		# time_accum += delta
		# if time_accum < 0.2: # aggiorna 5 volte al secondo
		# 	move_and_slide()
		# 	return
		# time_accum = 0.0
		look_at(target.global_transform.origin, Vector3.UP)
		var direction = (target.global_transform.origin - global_transform.origin).normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		if not is_on_floor():
			velocity.y -= GRAVITY * delta
		move_and_slide()


func _on_hurt_box_component_hurt(_weapon: Weapon, hit_position: Vector3, hit_normal: Vector3) -> void:
	spawn_blood(hit_position, hit_normal)

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

func _on_health_component_death() -> void:
	die.rpc()


func _on_hurt_box_component_body_entered(body: Node3D) -> void:
	if body is Truck:
		var truck: Truck = body
		hurt_box_component.hit.rpc(
			WeaponList.WeaponType.TRUCK,
			truck.global_transform.origin,
			truck.global_position.direction_to(global_transform.origin)
		)
