extends CharacterBody3D

@onready var physical_bone_simulator_3d: PhysicalBoneSimulator3D = $rig_CharRoot005/Object_245/Skeleton3D/PhysicalBoneSimulator3D
@onready var collision_shape_3d: CollisionShape3D = $MainCollisionShape
@export var target: Node3D
@export_range(0.1, 10.0, 0.1) var speed := 3.0
var GRAVITY = ProjectSettings.get_setting("physics/3d/default_gravity") * 10
var dead = false
@onready var animation_player: AnimationPlayer = $AnimationPlayer
var time_accum = 0.0
func _physics_process(delta):
	if not dead:
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
					animation_player.active = false
					collision_shape_3d.disabled = true
					physical_bone_simulator_3d.active = true
					physical_bone_simulator_3d.physical_bones_start_simulation()
					dead = true
