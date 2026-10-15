extends Node3D

@export var spawn_point: Node3D = null
@export var colors: Array[Color] = []
@export var chunk_manager: ChunkManager = null

var threads: Array[Thread] = [Thread.new()]
var chunk_renders: Dictionary[Vector3, Chunk]

func _ready() -> void:
	threads[0].start(generate_world)

func generate_world() -> void:
	for chunks in chunk_renders.values():
		call_deferred("remove_child", chunks)

	chunk_renders = chunk_manager.create(spawn_point, colors)

func _exit_tree() -> void:
	for thread in threads:
		thread.wait_to_finish()
