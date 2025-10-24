@tool
extends StaticBody3D

@onready var ray_cast_3d: RayCast3D = $RayCast3D
@onready var ray_cast_3d2: RayCast3D = $RayCast3D2
@onready var ray_cast_3d3: RayCast3D = $RayCast3D3
@onready var ray_cast_3d4: RayCast3D = $RayCast3D4

func _ready() -> void:
	snap_to_ground()

func snap_to_ground() -> void:
	ray_cast_3d.force_raycast_update()
	ray_cast_3d2.force_raycast_update()
	ray_cast_3d3.force_raycast_update()
	ray_cast_3d4.force_raycast_update()
	var normals := []
	var positions := []
	if ray_cast_3d.is_colliding():
		normals.append(ray_cast_3d.get_collision_normal())
		positions.append(ray_cast_3d.get_collision_point())
	if ray_cast_3d2.is_colliding():
		normals.append(ray_cast_3d2.get_collision_normal())
		positions.append(ray_cast_3d2.get_collision_point())
	if ray_cast_3d3.is_colliding():
		normals.append(ray_cast_3d3.get_collision_normal())
		positions.append(ray_cast_3d3.get_collision_point())
	if ray_cast_3d4.is_colliding():
		normals.append(ray_cast_3d4.get_collision_normal())
		positions.append(ray_cast_3d4.get_collision_point())
	if normals.size() == 0:
		return
	var average_normal := Vector3.ZERO
	for normal in normals:
		average_normal += normal
	average_normal /= normals.size()
	average_normal = average_normal.normalized()
	var average_position := Vector3.ZERO
	for pos in positions:
		average_position += pos
	average_position /= positions.size()
	global_transform.origin = average_position	
	# look_at_from_position(global_transform.origin, global_transform.origin + average_normal, Vector3.UP)
	look_at_from_position(global_position, global_position + average_normal, Vector3.FORWARD)
	rotate(Vector3.RIGHT, deg_to_rad(90))
	rotate(average_normal, deg_to_rad(randi_range(0, 360)))