extends Node

const CHARSET := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~"
var charset := {}

@export var player: Node3D
@export var render_distance: int = 4

var chunk_scene := preload("res://entities/chunks/chunk.tscn")

var last_chunk: Vector2


func _ready():
	for i in CHARSET.length():
		charset[CHARSET[i]] = i

	last_chunk = world_to_chunk(player.global_transform.origin)

	load_street(Vector2(0, 0), "A")


func _physics_process(delta: float):
	var chunk := world_to_chunk(player.global_transform.origin)


func world_to_chunk(world_pos: Vector3) -> Vector2:
	return Vector2(floor(world_pos.x / Chunk.CHUNK_WIDTH), -floor(world_pos.z / Chunk.CHUNK_DEPTH))


func chunk_to_world(chunk: Vector2) -> Vector3:
	return Vector3(chunk.x * Chunk.CHUNK_WIDTH, 0, -chunk.y * Chunk.CHUNK_DEPTH)


func load_street(chunk: Vector2, address: String):
	var code := encode(address)
	# go up and down
	for i in range(-render_distance, render_distance + 1):
		var new_chunk := Vector2(chunk.x, chunk.y + i)
		var new_address := decode(code + i)
		if new_address.length() != address.length():
			# underflow or overflow
			continue

		async_spawn_chunk(new_chunk, new_address, abs(i) * 0.5)


func async_spawn_chunk(chunk: Vector2, address: String, delay: float = 0.0):
	await get_tree().create_timer(delay).timeout
	spawn_chunk(chunk, address)


func spawn_chunk(chunk: Vector2, address: String):
	var new_chunk: Chunk = chunk_scene.instantiate()
	new_chunk.address = address
	new_chunk.transform.origin = chunk_to_world(chunk)
	add_child(new_chunk)


func encode(address: String) -> int:
	var res := 0
	for c in address:
		# shift by 1 to avoid breaking bijective mapping
		res = res * CHARSET.length() + charset[c] + 1
	return res


func decode(code: int) -> String:
	var res := ""
	while code > 0:
		code -= 1
		res += CHARSET[code % CHARSET.length()]
		code /= CHARSET.length()
	return res
