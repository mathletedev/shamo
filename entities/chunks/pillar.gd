extends Node3D
class_name Pillar

const PILLAR_WIDTH: float = 4
const PILLAR_DEPTH: float = 4
const MAX_HEIGHT: float = 20

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var pillar_mat := preload("res://entities/chunks/pillar.tres")

var datum: int
var delay: int

var y: float = 0
var target_y: float
var init_time: int


func _ready():
	visible = false
	init_time = Time.get_ticks_msec()

	# map [0..15] to [MAX_HEIGHT/16..MAX_HEIGHT]
	var height := (datum + 1) * (MAX_HEIGHT / 16)

	mesh.scale.y = height

	var shape := BoxShape3D.new()
	shape.extents = Vector3(PILLAR_WIDTH / 2, height / 2, PILLAR_DEPTH / 2)
	collision_shape.shape = shape

	y = -height / 2
	target_y = -y

	var new_mat: StandardMaterial3D = pillar_mat.duplicate()
	var l := datum / 15.0
	new_mat.albedo_color = Color(l, l, l)
	mesh.material_override = new_mat


func _process(delta):
	if Time.get_ticks_msec() >= init_time + delay:
		visible = true
		y = lerp(y, target_y, delta * 4)
		position.y = y
