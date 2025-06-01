extends Node

const CHARSET := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~"
var charset := {}

@export var player: Node3D
@export var render_distance: int = 4

var chunk_scene := preload("res://entities/chunks/chunk.tscn")

var chunks := {}


class ChunkData:
	var coords: Vector2
	var address: String


var chunk := ChunkData.new()


func _ready():
	for i in CHARSET.length():
		charset[CHARSET[i]] = i

	chunk.coords = world_to_chunk(player.global_transform.origin)
	chunk.address = "A"

	load_street(Vector2(0, 0), "A")


func _physics_process(_delta):
	var coords := world_to_chunk(player.global_transform.origin)
	if coords == chunk.coords:
		return

	# prevent "U" formation
	if coords.x > chunk.coords.x && chunks.has(chunk.coords):
		var next_address := decode(encode(chunk.address) * CHARSET.length() + 1)
		async_load_street(Vector2(chunk.coords.x + 1, coords.y), next_address, 1)
	elif coords.x < chunk.coords.x && coords.x >= 0:
		print("unloading street")
		unload_street(Vector2(chunk.coords.x, coords.y))

	if coords.y != chunk.coords.y:
		for i in range(-render_distance, 1):
			var dir := 1 if coords.y > chunk.coords.y else -1

			# next chunk
			var entering_view := coords.y + render_distance * dir
			var x := coords.x + i
			if chunks.has(Vector2(x, entering_view)):
				chunks[Vector2(x, entering_view)].undescend()
			elif (
				not chunks.has(Vector2(x, entering_view))
				and chunks.has(Vector2(x, entering_view - dir))
			):
				var furthest_chunk: Chunk = chunks[Vector2(x, entering_view - dir)]
				var next_address := decode(encode(furthest_chunk.address) + dir)
				# check for underflow or overflow
				if next_address.length() == chunks[furthest_chunk.coords].address.length():
					spawn_chunk(Vector2(x, entering_view), next_address)

			# chunk is too far back
			var exiting_view := coords.y - (render_distance + 1) * dir
			if chunks.has(Vector2(x, exiting_view)):
				destroy_chunk(Vector2(x, exiting_view))

	chunk.coords = coords
	chunk.address = "?" if not chunks.has(coords) else chunks[coords].address


func world_to_chunk(world_pos: Vector3) -> Vector2:
	return Vector2(floor(round(world_pos.x) / Chunk.WIDTH), -ceil(round(world_pos.z) / Chunk.DEPTH))


func chunk_to_world(coords: Vector2) -> Vector3:
	return Vector3(coords.x * Chunk.WIDTH, 0, -coords.y * Chunk.DEPTH)


func async_load_street(coords: Vector2, address: String, delay: float = 0.0):
	await get_tree().create_timer(delay).timeout
	load_street(coords, address)


func load_street(coords: Vector2, address: String):
	var code := encode(address)
	# go up and down
	for i in range(0, render_distance + 1):
		var new_chunk := Vector2(coords.x, coords.y + i)
		var new_address := decode(code + i)
		if new_address.length() != address.length():
			# underflow or overflow
			continue

		spawn_chunk(new_chunk, new_address, abs(i) * 500)


func unload_street(coords: Vector2):
	for i in range(-render_distance, render_distance + 1):
		if not chunks.has(Vector2(coords.x, coords.y + i)):
			continue

		destroy_chunk(Vector2(coords.x, coords.y + i), (render_distance - abs(i)) * 500)


func spawn_chunk(coords: Vector2, address: String, delay: int = 0):
	var new_chunk: Chunk = chunk_scene.instantiate()
	new_chunk.coords = coords
	new_chunk.address = address
	new_chunk.delay = delay
	new_chunk.transform.origin = chunk_to_world(coords)
	chunks[coords] = new_chunk
	add_child(new_chunk)


func destroy_chunk(coords: Vector2, delay: int = 0):
	if not chunks.has(coords):
		return

	chunks[coords].descend(delay)

	await get_tree().create_timer(delay / 1000.0 + Chunk.KEEP_ALIVE_TIME).timeout
	if chunks[coords].descending:
		# destroy if hasn't undestroyed yet
		chunks[coords].queue_free()
		chunks.erase(coords)


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
