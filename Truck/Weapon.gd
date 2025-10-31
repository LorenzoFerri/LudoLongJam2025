extends Node3D

const bullet_scene = preload("res://Weapon/Projectiles/Bullet.tscn")

@onready var x_rotation_control = $Rotate_Z/Rotate_X
@onready var z_rotation_control = $Rotate_Z
# @onready var camera_arm: SpringArm3D = $CameraArm
@onready var camera: Camera3D = %Camera3D
# Called when the node enters the scene tree for the first time.
@onready var shooting_timer: Timer = $ShootingTimer
@onready var shooting_raycast: RayCast3D = %ShootingRaycast
@onready var bullets_group: Node3D = $Bullets

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
	var bullet = bullet_scene.instantiate()
	bullet.start_position = shooting_raycast.global_position
	var target = x_rotation_control.global_transform * shooting_raycast.target_position
	bullet.end_position = bullet.start_position + target
	bullets_group.add_child(bullet)
	
	if shooting_raycast.is_colliding():
		var collider = shooting_raycast.get_collider()
