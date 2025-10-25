@tool
extends StaticBody3D
class_name TerrainChunk
var _heightmap: Array

var rocks_scenes = [
	preload("res://Rocks/BigRock1.tscn"),
	preload("res://Rocks/BigRock2.tscn"),
	preload("res://Rocks/BigRock3.tscn"),
	preload("res://Rocks/MediumRock1.tscn"),
	preload("res://Rocks/MediumRock2.tscn"),
	preload("res://Rocks/MediumRock3.tscn"),
	preload("res://Rocks/MediumRock4.tscn"),
	preload("res://Rocks/MediumRock5.tscn"),
	preload("res://Rocks/SmallRock1.tscn"),
	preload("res://Rocks/SmallRock2.tscn"),
	preload("res://Rocks/SmallRock3.tscn"),
	preload("res://Rocks/SmallRock4.tscn"),
	preload("res://Rocks/SmallRock5.tscn"),
	preload("res://Rocks/SmallRock6.tscn")
]

## Singolo chunk del terreno con mesh e collisione

var mesh_instance: MeshInstance3D
var collision_shape: CollisionShape3D

func _init() -> void:
	# Crea MeshInstance3D
	mesh_instance = MeshInstance3D.new()
	add_child(mesh_instance)
	
	# Crea CollisionShape3D
	collision_shape = CollisionShape3D.new()
	add_child(collision_shape)

func generate_mesh(heightmap: Array, chunk_size: int, resolution: int, material: Material = null, height_calculator: Callable = Callable(), chunk_pos: Vector2i = Vector2i.ZERO, world_seed: int = 0) -> void:
	_heightmap = heightmap
	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	var step := float(chunk_size) / float(resolution)
	var world_x := chunk_pos.x * chunk_size
	var world_z := chunk_pos.y * chunk_size
	
	# Crea un seed deterministico basato sulla posizione del chunk e sul seed del mondo
	var chunk_seed := hash(Vector2i(chunk_pos.x, chunk_pos.y)) ^ world_seed
	var rng := RandomNumberGenerator.new()
	rng.seed = chunk_seed

	# Precalcola i vertici, calcolando le altezze anche oltre i bordi usando il noise
	# Espandi la griglia di 1 vertice in ogni direzione per calcolare le normali ai bordi
	var vertices := []
	for z in range(-1, resolution + 2):
		var row := []
		for x in range(-1, resolution + 2):
			var h: float = 0.0
			# Calcola l'altezza usando il noise per tutti i vertici (anche oltre i bordi)
			if height_calculator.is_valid():
				var wx := int(world_x + (x * step))
				var wz := int(world_z + (z * step))
				h = height_calculator.call(wx, wz)
			else:
				# Fallback: usa heightmap se disponibile
				if z >= 0 and z <= resolution and x >= 0 and x <= resolution:
					h = heightmap[z][x]
			# Coordinate locali del vertice (relative al chunk)
			var local_x := x * step
			var local_z := z * step
			row.append(Vector3(local_x, h, local_z))
		vertices.append(row)

	# Precalcola le normali per ogni vertice
	var normals := []
	for z in range(-1, resolution + 2):
		var row := []
		for x in range(-1, resolution + 2):
			row.append(Vector3.ZERO)
		normals.append(row)

	# Calcola le normali delle facce e accumula sulle normali dei vertici
	# Includi anche i triangoli oltre i bordi per calcolare le normali correttamente
	for z in range(-1, resolution + 1):
		for x in range(-1, resolution + 1):
			var v1: Vector3 = vertices[z + 1][x + 1]
			var v2: Vector3 = vertices[z + 1][x + 2]
			var v3: Vector3 = vertices[z + 2][x + 1]
			var v4: Vector3 = vertices[z + 2][x + 2]

			# Primo triangolo (v1, v2, v3)
			var normal1 := _calculate_normal(v1, v2, v3)
			normals[z + 1][x + 1] += normal1
			normals[z + 1][x + 2] += normal1
			normals[z + 2][x + 1] += normal1

			# Secondo triangolo (v2, v4, v3)
			var normal2 := _calculate_normal(v2, v4, v3)
			normals[z + 1][x + 2] += normal2
			normals[z + 2][x + 2] += normal2
			normals[z + 2][x + 1] += normal2

	# Normalizza le normali
	for z in range(-1, resolution + 2):
		for x in range(-1, resolution + 2):
			normals[z + 1][x + 1] = normals[z + 1][x + 1].normalized()

	# Costruisci la mesh con normali smooth
	# Usa solo i vertici del chunk (offset +1 perché abbiamo espanso la griglia)
	for z in range(resolution):
		for x in range(resolution):
			var v1: Vector3 = vertices[z + 1][x + 1]
			var v2: Vector3 = vertices[z + 1][x + 2]
			var v3: Vector3 = vertices[z + 2][x + 1]
			var v4: Vector3 = vertices[z + 2][x + 2]

			var n1: Vector3 = normals[z + 1][x + 1]
			var n2: Vector3 = normals[z + 1][x + 2]
			var n3: Vector3 = normals[z + 2][x + 1]
			var n4: Vector3 = normals[z + 2][x + 2]

			# Primo triangolo (v1, v2, v3)
			surface_tool.set_normal(n1)
			surface_tool.set_uv(Vector2(float(x) / resolution, float(z) / resolution))
			surface_tool.add_vertex(v1)

			surface_tool.set_normal(n2)
			surface_tool.set_uv(Vector2(float(x + 1) / resolution, float(z) / resolution))
			surface_tool.add_vertex(v2)

			surface_tool.set_normal(n3)
			surface_tool.set_uv(Vector2(float(x) / resolution, float(z + 1) / resolution))
			surface_tool.add_vertex(v3)

			# Secondo triangolo (v2, v4, v3)
			surface_tool.set_normal(n2)
			surface_tool.set_uv(Vector2(float(x + 1) / resolution, float(z) / resolution))
			surface_tool.add_vertex(v2)

			surface_tool.set_normal(n4)
			surface_tool.set_uv(Vector2(float(x + 1) / resolution, float(z + 1) / resolution))
			surface_tool.add_vertex(v4)

			surface_tool.set_normal(n3)
			surface_tool.set_uv(Vector2(float(x) / resolution, float(z + 1) / resolution))
			surface_tool.add_vertex(v3)
	
	# Crea la mesh
	var array_mesh := surface_tool.commit()
	mesh_instance.mesh = array_mesh
	
	# Applica il materiale come override globale
	if material != null:
		mesh_instance.material_override = material
	else:
		var default_material := StandardMaterial3D.new()
		default_material.albedo_color = Color(0.3, 0.6, 0.3)
		mesh_instance.material_override = default_material
	
	# Genera rocce in modo deterministico basato sul seed del chunk
	if rng.randi_range(0, 18) == 0:
		var rock: StaticBody3D = rocks_scenes[rng.randi_range(0, rocks_scenes.size() - 1)].instantiate()
		add_child(rock)
		rock.position.y = 15
		# var v = vertices[float(resolution) / 2][float(resolution) / 2]
		# rock.position.y = v.y - 1.3
		# var norm = normals[float(resolution) / 2][float(resolution) / 2]
		# rock.look_at_from_position(rock.position, rock.position + norm, Vector3.FORWARD)
		# rock.rotate(Vector3.RIGHT, deg_to_rad(90))
		# rock.rotate(norm, deg_to_rad(rng.randi_range(0, 360)))
	
	# Crea collisione
	_create_collision(vertices, chunk_size, resolution)

func _create_collision(vertices: Array, _chunk_size: int, resolution: int) -> void:
	# Non creare collisione nell'editor per performance
	if Engine.is_editor_hint():
		return
	
	# Crea una ConcavePolygonShape3D invece di HeightMapShape3D per maggiore precisione
	var faces := PackedVector3Array()
	
	# Usa i vertici della mesh (con offset +1 perché la griglia è espansa)
	for z in range(resolution):
		for x in range(resolution):
			var v1: Vector3 = vertices[z + 1][x + 1]
			var v2: Vector3 = vertices[z + 1][x + 2]
			var v3: Vector3 = vertices[z + 2][x + 1]
			var v4: Vector3 = vertices[z + 2][x + 2]
			
			# Primo triangolo (v1, v2, v3)
			faces.append(v1)
			faces.append(v2)
			faces.append(v3)
			
			# Secondo triangolo (v2, v4, v3)
			faces.append(v2)
			faces.append(v4)
			faces.append(v3)
	
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	collision_shape.shape = shape

func _calculate_normal(v1: Vector3, v2: Vector3, v3: Vector3) -> Vector3:
	var edge1 := v2 - v1
	var edge2 := v3 - v1
	return edge2.cross(edge1).normalized()
