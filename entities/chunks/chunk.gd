extends Node3D
class_name Chunk

const WIDTH: int = 40
const DEPTH: int = 40
const ROWS: int = 8
const COLS: int = 8
const MARGIN_X: float = (WIDTH - Pillar.WIDTH * COLS) / 2.0
const MARGIN_Y: float = (DEPTH - Pillar.DEPTH * ROWS) / 2.0
const INIT_DELAY: int = 1000
const INIT_HEIGHT: float = -8
const KEEP_ALIVE_TIME: int = 3

var pillar_scene := preload("res://entities/chunks/pillar.tscn")

var coords: Vector2
var address: String
var delay: int
var descending := false

var pillars := Array()
var init_time: int


func _ready():
	# malloc pillars
	pillars.resize(ROWS)
	for i in range(0, ROWS):
		pillars[i] = Array()
		pillars[i].resize(COLS)

	position.y = INIT_HEIGHT
	init_time = Time.get_ticks_msec()

	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(address.to_utf8_buffer())
	var digest := ctx.finish()

	for i in range(0, ROWS):
		for j in range(0, COLS):
			# index into the hash by doubles
			@warning_ignore("integer_division")
			var nibble := digest[(i * COLS + j) / 2]
			if j % 2 == 0:
				# take first half of the byte
				nibble = nibble >> 4
			else:
				# take second half of the byte
				nibble = nibble & 0x0F

			var pillar: Pillar = pillar_scene.instantiate()
			pillar.name = str(i) + "_" + str(j)
			# INFO: chunk is rotated 90 degrees
			pillar.position.z = MARGIN_X + j * Pillar.WIDTH
			pillar.position.x = MARGIN_Y + i * Pillar.DEPTH
			pillar.datum = nibble
			pillar.delay = (delay + INIT_DELAY + (abs(ROWS / 2.0 - i) + abs(COLS / 2.0 - j)) * 200)
			pillars[i][j] = pillar
			add_child(pillar)


func _process(delta):
	if Time.get_ticks_msec() >= init_time + delay:
		visible = true
		position.y = lerp(position.y, INIT_HEIGHT if descending else 0.0, delta * 2)


func descend(new_delay: int = 0):
	# start descending back into ground
	descending = true
	init_time = Time.get_ticks_msec()
	delay = new_delay

	await get_tree().create_timer(delay / 1000.0).timeout
	for i in range(0, ROWS):
		for j in range(0, COLS):
			pillars[i][j].descending = true


func undescend():
	descending = false
	for i in range(0, ROWS):
		for j in range(0, COLS):
			pillars[i][j].descending = false
