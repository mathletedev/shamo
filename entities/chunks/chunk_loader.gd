extends Node

var chunk_scene := preload("res://entities/chunks/chunk.tscn")


func _ready():
	for i in range(0, 10):
		var chunk: Chunk = chunk_scene.instantiate()
		chunk.position.x = i * 40
		chunk.address = str(i)
		add_child(chunk)
