extends Node

const CHARSET := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~"
var charset := {}

@export var player: Node3D
@export var render_distance: int = 4

var chunk_scene := preload("res://entities/chunks/chunk.tscn")

var last_chunk: Vector2
var max_x: int = 0
var last_address: String


func _ready():
	for i in CHARSET.length():
		charset[CHARSET[i]] = i

	last_chunk = world_to_chunk(player.global_transform.origin)
	last_address = "A"

	load_street(Vector2(0, 0), "A")


func _physics_process(_delta):
	var chunk := world_to_chunk(player.global_transform.origin)
	if chunk == last_chunk:
		return

	if chunk.x == last_chunk.x:
		pass
	elif chunk.x > max_x:
		var next_address := decode(encode(last_address) * CHARSET.length() + 1)
		async_load_street(Vector2(last_chunk.x + 1, 0), next_address, 0.5)
		last_address = next_address

	last_chunk = chunk
	max_x = max(max_x, chunk.x)


func world_to_chunk(world_pos: Vector3) -> Vector2:
	return Vector2(
		floor(round(world_pos.x) / Chunk.CHUNK_WIDTH), -ceil(round(world_pos.z) / Chunk.CHUNK_DEPTH)
	)


func chunk_to_world(chunk: Vector2) -> Vector3:
	return Vector3(chunk.x * Chunk.CHUNK_WIDTH, 0, -chunk.y * Chunk.CHUNK_DEPTH)


func async_load_street(chunk: Vector2, address: String, delay: float = 0.0):
	await get_tree().create_timer(delay).timeout
	load_street(chunk, address)


func load_street(chunk: Vector2, address: String):
	var code := encode(address)
	# go up and down
	for i in range(-render_distance, render_distance + 1):
		var new_chunk := Vector2(chunk.x, chunk.y + i)
		var new_address := decode(code + i)
		if new_address.length() != address.length():
			# underflow or overflow
			continue

		spawn_chunk(new_chunk, new_address, abs(i) * 500)


func spawn_chunk(chunk: Vector2, address: String, delay: int = 0):
	var new_chunk: Chunk = chunk_scene.instantiate()
	new_chunk.address = address
	new_chunk.delay = delay
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
