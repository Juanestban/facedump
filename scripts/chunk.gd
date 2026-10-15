class_name Chunk extends Node3D

enum Direction {
	Down,
	Front,
	Right,
	Up,
	Left,
	Back
}

var capacity: int = 16
var height: int = 10
var world_position: Vector3 = Vector3.ZERO
var use_colors: bool = true
var max_height: int = 0

var mesh_instance: MeshInstance3D
var collision: CollisionShape3D

var voxels: Dictionary[Vector3, Color] = {}

var surface_array: Array = []
var vertices: PackedVector3Array = PackedVector3Array()
var normals: PackedVector3Array = PackedVector3Array()
var colors : PackedColorArray = PackedColorArray()
# var uv: PackedVector3Array

const DIRECTIONS: Array[Direction] = [
	Direction.Front,
	Direction.Back,
	Direction.Left,
	Direction.Right,
	Direction.Up,
	Direction.Down
]

const CUBE_VERTICES: Array[Vector3] = [
	Vector3(-0.5, -0.5, 0.5),
	Vector3(0.5, -0.5, 0.5),
	Vector3(0.5, -0.5, -0.5),
	Vector3(-0.5, -0.5, -0.5),
	Vector3(-0.5, 0.5, 0.5),
	Vector3(0.5, 0.5, 0.5),
	Vector3(0.5, 0.5, -0.5),
	Vector3(-0.5, 0.5, -0.5),
]

const FACES_INDICES: Dictionary[Direction, Array] = {
	Direction.Front: [[0, 4, 5], [0, 5, 1]],
	Direction.Back: [[2, 7, 3], [2, 6, 7]],
	Direction.Left: [[3, 7, 4], [3, 4, 0]],
	Direction.Right: [[1, 5, 6], [1, 6, 2]],
	Direction.Down: [[0, 1, 2], [0, 2, 3]],
	Direction.Up: [[4, 7, 6], [4, 6, 5]],
}

const FACE_VERTEX_ORDER: Dictionary[Direction, Array] = {
	Direction.Front: [0, 1, 5, 4], # z+
	Direction.Back: [2, 3, 7, 6], # z-
	Direction.Left: [3, 7, 4, 0], # x-
	Direction.Right: [1, 5, 6, 2], # x+
	Direction.Down: [0, 1, 2, 3], # y-
	Direction.Up: [4, 5, 6, 7] # y+
}

const FACES_NORMALS: Dictionary[Direction, Vector3] = {
	Direction.Front: Vector3(0, 0, 1),
	Direction.Back: Vector3(0, 0, -1),
	Direction.Left: Vector3(-1, 0, 0),
	Direction.Right: Vector3(1, 0, 0),
	Direction.Down: Vector3(0, -1, 0),
	Direction.Up: Vector3(0, 1, 0),
}

func _ready() -> void:
	surface_array.resize(Mesh.ARRAY_MAX)
	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = ArrayMesh.new()
	collision = CollisionShape3D.new()

	add_child(mesh_instance)
	add_child(collision)

	if voxels.is_empty():
		return

	commit_mesh()

func has_neighbour(face: Direction, pos: Vector3) -> bool:
	var neighbour_position = pos + FACES_NORMALS[face]
	return voxels.has(neighbour_position)

func create_mesh(pos: Vector3) -> void:
	if voxels.is_empty():
		return

	for direction in DIRECTIONS:
		if not has_neighbour(direction, pos):
			var color = voxels[pos]
			add_face(direction, pos, color)

func add_face(direction: Direction, pos: Vector3, color: Color) -> void:
	var face_indices = FACES_INDICES[direction]
	var face_order = FACE_VERTEX_ORDER[direction]

	for triangle in face_indices:
		for index in triangle:
			var quad_pos = face_order.find(index)
			
			if quad_pos == -1:
				quad_pos = 0

			vertices.append(CUBE_VERTICES[index] + pos)
			normals.append(FACES_NORMALS[direction])
			colors.append(color)

func commit_mesh() -> void:
	surface_array[Mesh.ARRAY_VERTEX] = vertices
	surface_array[Mesh.ARRAY_NORMAL] = normals
	
	if use_colors:
		surface_array[Mesh.ARRAY_COLOR] = colors

	var mat = StandardMaterial3D.new()
	mesh_instance.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	mat.vertex_color_use_as_albedo = true
	mesh_instance.mesh.surface_set_material(0, mat)
	collision.shape = mesh_instance.mesh.create_trimesh_shape()

func create(noise: Noise, picolors: Array[Color]) -> void:
	for x in range(capacity):
		for z in range(capacity):
			var wx = x + world_position.x
			var wz = z + world_position.z

			var rand = ((noise.get_noise_2d(wx, wz) + 0.5 * noise.get_noise_2d(wx * 2, wz * 2) + 0.25 * noise.get_noise_2d(wx * 4, wz * 4)) / 1.75 + 1) / 2
			var rand_pow = pow(rand, 2.1)
			var custom_height = height * rand_pow

			if custom_height < world_position.y:
				continue

			var local_height = custom_height - world_position.y

			for y in range(min(local_height, height)):
				if y > max_height:
					max_height = y

				voxels[Vector3(x, y, z)] = picolors[y % picolors.size()]

	set_blocks()

func set_blocks() -> void:
	for pos in voxels:
		create_mesh(pos)

func get_cubes_length() -> int:
	return voxels.size()

func get_max_height() -> int:
	return max_height
