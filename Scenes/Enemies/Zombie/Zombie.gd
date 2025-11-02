extends CharacterBody3D
class_name Zombie

@onready var physical_bone_simulator_3d: PhysicalBoneSimulator3D = $rig_CharRoot005/Object_245/Skeleton3D/PhysicalBoneSimulator3D
@onready var collision_shape_3d: CollisionShape3D = $MainCollisionShape
@export_node_path var target_path: NodePath
var target: Node3D
@export_range(0.1, 10.0, 0.1) var speed := 3.0
var GRAVITY = ProjectSettings.get_setting("physics/3d/default_gravity") * 10
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@export var dead = false
var ragdoll_started = false
var time_accum = 0.0

func _ready() -> void:
	target = get_node_or_null(target_path)

func _physics_process(delta):
	if multiplayer.is_server():
		if dead: return
		time_accum += delta
		if time_accum < 0.2: # aggiorna 5 volte al secondo
			move_and_slide()
			return
		time_accum = 0.0
		look_at(target.global_transform.origin, Vector3.UP)
		var direction = (target.global_transform.origin - global_transform.origin).normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		if not is_on_floor():
			velocity.y -= GRAVITY * delta
		move_and_slide()
		for i in range(get_slide_collision_count()):
			var collision_info = get_slide_collision(i)
			if collision_info:
				var collider = collision_info.get_collider()
				if collider.is_class("VehicleBody3D"):				
					dead = true
	if dead and not ragdoll_started:
		animation_player.active = false
		collision_shape_3d.disabled = true
		physical_bone_simulator_3d.active = true
		physical_bone_simulator_3d.physical_bones_start_simulation()
		ragdoll_started = true
