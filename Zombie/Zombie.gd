extends CharacterBody3D

@export var target: Node3D
@export_range(0.1, 10.0, 0.1) var speed := 3.0
var GRAVITY = ProjectSettings.get_setting("physics/3d/default_gravity")

var time_accum = 0.0
func _physics_process(delta):
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
