class_name ChunkManager extends Node

@export var capacity: int = 16
@export var height: int = 10
@export var chunk_size: int = 6

var cube_len: int = 0
var perlinoise = FastNoiseLite.new()
# change world builder this seed
var noise_seed = 0

func _ready() -> void:
	var monitor_name = "voxel_performance"

	if not Performance.has_custom_monitor(monitor_name):
		Performance.add_custom_monitor(monitor_name, func(): return cube_len)

	perlinoise.noise_type = FastNoiseLite.TYPE_PERLIN
	perlinoise.frequency = 0.003
	perlinoise.seed = noise_seed

func create(_sp: Node3D, colors: Array[Color]) -> Dictionary[Vector3, Chunk]:
	var chunk_renders: Dictionary[Vector3, Chunk] = {}
	var start_time = Time.get_ticks_usec()

	for x in range(chunk_size):
		for z in range(chunk_size):
			var chunk = Chunk.new()
			var pos: Vector3 = Vector3(x * capacity, -0.5, z * capacity)

			chunk.capacity = capacity
			chunk.height = height
			chunk.world_position = pos
			chunk.position = pos

			chunk.create(perlinoise, colors)
			cube_len += chunk.get_cubes_length()
			call_deferred("add_child", chunk)
			chunk_renders[pos] = chunk

			#@warning_ignore("integer_division")
			#if x == roundi(chunk_size / 2) and z == roundi(chunk_size / 2):
				#sp.global_position = Vector3(chunk.world_position.x, chunk.get_max_height(), chunk.world_position.z)

	var end_time = Time.get_ticks_usec()
	var gen_time = (end_time - start_time) / 1000000.0
	print_debug("blocks in world %s\nGenerate Time %s" % [cube_len, gen_time])

	return chunk_renders
