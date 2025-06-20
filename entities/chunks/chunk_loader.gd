extends Node

const CHARSET := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~"
var charset := {}

signal chunk_changed(chunk: Chunk)

@export var player: Node3D
@export var render_distance: int = 4

var chunk_scene := preload("res://entities/chunks/chunk.tscn")
var ocean_chunk_scene := preload("res://entities/water/ocean_chunk.tscn")

var chunks := {}
var ocean_chunks := {}


class ChunkData:
	var coords: Vector2i
	var address: String


var chunk := ChunkData.new()
var ocean_coords: Vector2i


func _ready():
	for i in CHARSET.length():
		charset[CHARSET[i]] = i

	chunk.coords = world_to_chunk(player.global_transform.origin)
	chunk.address = "A"

	load_street(Vector2(0, 0))

	ocean_coords = world_to_ocean_chunk(player.global_transform.origin)

	for i in range(-1, 2):
		for j in range(-1, 2):
			spawn_ocean_chunk(Vector2i(i, j))

	emit_signal("chunk_changed", chunks[chunk.coords])


func _physics_process(_delta):
	var coords := world_to_chunk(player.global_transform.origin)
	if coords == chunk.coords:
		return

	# prevent "U" formation
	if coords.x > chunk.coords.x && chunks.has(chunk.coords):
		load_street(Vector2i(chunk.coords.x + 1, coords.y), chunk.address)
	elif coords.x < chunk.coords.x && coords.x >= 0:
		unload_street(Vector2i(chunk.coords.x, coords.y))

	# handle chunks
	if coords.y != chunk.coords.y:
		for i in range(-render_distance, 1):
			var x := coords.x + i
			if not chunks.has(Vector2i(x, coords.y)):
				continue

			var dir := 1 if coords.y > chunk.coords.y else -1

			# next chunk
			var entering_view := coords.y + render_distance * dir
			if chunks.has(Vector2i(x, entering_view)):
				chunks[Vector2i(x, entering_view)].undescend()
			elif (
				not chunks.has(Vector2i(x, entering_view))
				and chunks.has(Vector2i(x, entering_view - dir))
			):
				var furthest_chunk: Chunk = chunks[Vector2i(x, entering_view - dir)]
				var code: int = charset[chunk.address[coords.x]] + dir
				# check for underflow or overflow
				if code >= 0 and code < CHARSET.length():
					var next_address := furthest_chunk.address.substr(0, coords.x) + CHARSET[code]
					spawn_chunk(Vector2i(x, entering_view), next_address)

			# chunk is too far back
			var exiting_view := coords.y - (render_distance + 1) * dir
			if chunks.has(Vector2i(x, exiting_view)):
				destroy_chunk(Vector2i(x, exiting_view))

	# broadcast signal
	chunk.coords = coords
	chunk.address = "?" if not chunks.has(coords) else chunks[coords].address

	if chunks.has(coords):
		emit_signal("chunk_changed", chunks[coords])
	else:
		var tmp := Chunk.new()
		tmp.coords = coords
		tmp.address = "?"
		tmp.digest = []
		emit_signal("chunk_changed", tmp)

	# handle ocean chunks
	var new_ocean_coords := world_to_ocean_chunk(player.global_transform.origin)
	if new_ocean_coords == ocean_coords:
		return

	if ocean_coords.x != new_ocean_coords.x:
		var dir := 1 if new_ocean_coords.x > ocean_coords.x else -1
		for i in range(-1, 2):
			spawn_ocean_chunk(Vector2i(new_ocean_coords.x + dir, new_ocean_coords.y + i))
			destroy_ocean_chunk(Vector2i(ocean_coords.x - dir, new_ocean_coords.y + i))
	if ocean_coords.y != new_ocean_coords.y:
		var dir := 1 if new_ocean_coords.y > ocean_coords.y else -1
		for i in range(-1, 2):
			spawn_ocean_chunk(Vector2i(new_ocean_coords.x + i, new_ocean_coords.y + dir))
			destroy_ocean_chunk(Vector2i(new_ocean_coords.x + i, ocean_coords.y - dir))

	ocean_coords = new_ocean_coords


func world_to_chunk(world_pos: Vector3) -> Vector2i:
	return Vector2i(
		floor(round(world_pos.x) / Chunk.WIDTH), -ceil(round(world_pos.z) / Chunk.DEPTH)
	)


func world_to_ocean_chunk(world_pos: Vector3) -> Vector2i:
	return Vector2i(
		floor(round(world_pos.x) / (4 * Chunk.WIDTH)), -ceil(round(world_pos.z) / (4 * Chunk.DEPTH))
	)


func chunk_to_world(coords: Vector2i) -> Vector3:
	return Vector3(coords.x * Chunk.WIDTH, 0, -coords.y * Chunk.DEPTH)


func load_street(coords: Vector2i, address: String = ""):
	# go up and down
	for i in range(0, render_distance + 1):
		var new_coords := Vector2i(coords.x, coords.y + i)

		if chunks.has(new_coords):
			chunks[new_coords].undescend()
		else:
			# code starts at A = 0
			var new_address: String = address + CHARSET[i]
			spawn_chunk(new_coords, new_address, abs(i) * 500)


func unload_street(coords: Vector2i):
	for i in range(-render_distance, render_distance + 1):
		if not chunks.has(Vector2i(coords.x, coords.y + i)):
			continue

		destroy_chunk(Vector2i(coords.x, coords.y + i), (render_distance - abs(i)) * 500)


func spawn_chunk(coords: Vector2i, address: String, delay: int = 0):
	var new_chunk: Chunk = chunk_scene.instantiate()
	new_chunk.coords = coords
	new_chunk.address = address
	new_chunk.delay = delay
	new_chunk.transform.origin = chunk_to_world(coords)
	chunks[coords] = new_chunk
	add_child(new_chunk)


func destroy_chunk(coords: Vector2i, delay: int = 0):
	if not chunks.has(coords):
		return

	chunks[coords].descend(delay)

	await get_tree().create_timer(delay / 1000.0 + Chunk.KEEP_ALIVE_TIME).timeout
	if chunks.has(coords) and chunks[coords].d55727675escending:
		# destroy if hasn't undestroyed yet
		chunks[coords].queue_free()
		chunks.erase(coords)


func spawn_ocean_chunk(coords: Vector2i):
	var ocean_chunk: Node3D = ocean_chunk_scene.instantiate()
	ocean_chunk.position.x = coords.x * 4 * Chunk.WIDTH
	ocean_chunk.position.z = -coords.y * 4 * Chunk.DEPTH
	ocean_chunks[Vector2i(coords.x, coords.y)] = ocean_chunk
	add_child(ocean_chunk)


func destroy_ocean_chunk(coords: Vector2i):
	if not ocean_chunks.has(coords):
		return

	ocean_chunks[coords].queue_free()
