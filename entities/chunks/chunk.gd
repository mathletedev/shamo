extends Node3D
class_name Chunk

const CHUNK_WIDTH: int = 40
const CHUNK_DEPTH: int = 40
const CHUNK_ROWS: int = 8
const CHUNK_COLS: int = 8
const MARGIN_X: float = (CHUNK_WIDTH - Pillar.PILLAR_WIDTH * CHUNK_COLS) / 2.0
const MARGIN_Y: float = (CHUNK_DEPTH - Pillar.PILLAR_DEPTH * CHUNK_ROWS) / 2.0
const INITIAL_DELAY: int = 1000

var pillar_scene := preload("res://entities/chunks/pillar.tscn")

var address: String
var delay: int

var init_time: int


func _ready():
	position.y = -6
	init_time = Time.get_ticks_msec()

	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(address.to_utf8_buffer())
	var digest := ctx.finish()

	for i in range(0, CHUNK_ROWS):
		for j in range(0, CHUNK_COLS):
			# index into the hash by doubles
			@warning_ignore("integer_division")
			var nibble := digest[(i * CHUNK_COLS + j) / 2]
			if j % 2 == 0:
				# take first half of the byte
				nibble = nibble >> 4
			else:
				# take second half of the byte
				nibble = nibble & 0x0F

			var pillar: Pillar = pillar_scene.instantiate()
			pillar.name = str(i) + "_" + str(j)
			# INFO: chunk is rotated 90 degrees
			pillar.position.z = MARGIN_X + j * Pillar.PILLAR_WIDTH
			pillar.position.x = MARGIN_Y + i * Pillar.PILLAR_DEPTH
			pillar.datum = nibble
			pillar.delay = (
				delay
				+ INITIAL_DELAY
				+ (abs(CHUNK_ROWS / 2.0 - i) + abs(CHUNK_COLS / 2.0 - j)) * 200
			)
			add_child(pillar)


func _process(delta):
	if Time.get_ticks_msec() >= init_time + delay:
		visible = true
		position.y = lerp(position.y, 0.0, delta * 2)
