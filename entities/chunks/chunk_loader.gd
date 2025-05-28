extends Node

var chunk_scene := preload("res://entities/chunks/chunk.tscn")


func _ready():
	var chunk: Chunk = chunk_scene.instantiate()
	chunk.address = "Hello, world!"
	add_child(chunk)
