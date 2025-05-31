extends Node

const CHARSET := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~"
var charset := {}

@export var player: Node3D
@export var render_distance: int = 4

var chunk_scene := preload("res://entities/chunks/chunk.tscn")

var chunks := {}
var last_chunk: Vector2
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

	if chunk.x > last_chunk.x:
		var next_address := decode(encode(last_address) * CHARSET.length() + 1)
		async_load_street(Vector2(last_chunk.x + 1, chunk.y), next_address, 1)
		last_address = next_address
	elif chunk.x < last_chunk.x:
		unload_street(Vector2(last_chunk.x, chunk.y))

	last_chunk = chunk


func world_to_chunk(world_pos: Vector3) -> Vector2:
	return Vector2(floor(round(world_pos.x) / Chunk.WIDTH), -ceil(round(world_pos.z) / Chunk.DEPTH))


func chunk_to_world(chunk: Vector2) -> Vector3:
	return Vector3(chunk.x * Chunk.WIDTH, 0, -chunk.y * Chunk.DEPTH)


func async_load_street(chunk: Vector2, address: String, delay: float = 0.0):
	await get_tree().create_timer(delay).timeout
	load_street(chunk, address)


func load_street(chunk: Vector2, address: String):
	var code := encode(address)
	# go up and down
	for i in range(0, render_distance + 1):
		var new_chunk := Vector2(chunk.x, chunk.y + i)
		var new_address := decode(code + i)
		if new_address.length() != address.length():
			# underflow or overflow
			continue

		spawn_chunk(new_chunk, new_address, abs(i) * 500)


func unload_street(chunk: Vector2):
	for i in range(-render_distance, render_distance + 1):
		if not chunks.has(Vector2(chunk.x, chunk.y + i)):
			continue

		destroy_chunk(Vector2(chunk.x, chunk.y + i), (render_distance - abs(i)) * 500)


func spawn_chunk(chunk: Vector2, address: String, delay: int = 0):
	var new_chunk: Chunk = chunk_scene.instantiate()
	new_chunk.address = address
	new_chunk.delay = delay
	new_chunk.transform.origin = chunk_to_world(chunk)
	chunks[chunk] = new_chunk
	add_child(new_chunk)


func destroy_chunk(chunk: Vector2, delay: int = 0):
	if not chunks.has(chunk):
		return

	chunks[chunk].descend(delay)

	await get_tree().create_timer(delay / 1000.0 + Chunk.KEEP_ALIVE_TIME).timeout
	if chunks[chunk].descending:
		# destroy if hasn't undestroyed yet
		chunks[chunk].queue_free()
		chunks.erase(chunk)


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
