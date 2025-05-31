extends Node3D
class_name Pillar

const WIDTH: float = 4
const DEPTH: float = 4
const MAX_HEIGHT: float = 20

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var pillar_mat := preload("res://entities/chunks/pillar.tres")

var datum: int
var delay: int
var descending := false

var target_y: float
var init_time: int


func _ready():
	visible = false
	init_time = Time.get_ticks_msec()

	# map [0..15] to [MAX_HEIGHT/16..MAX_HEIGHT]
	var height := (datum + 1) * (MAX_HEIGHT / 16)

	# simplify: just make height default to 20
	# mesh.scale.y = height

	# var shape := BoxShape3D.new()
	# shape.extents = Vector3(WIDTH / 2, height / 2, DEPTH / 2)
	# collision_shape.shape = shape

	# y = -height / 2
	# target_y = -y

	target_y = height

	var new_mat: StandardMaterial3D = pillar_mat.duplicate()
	var l := datum / 15.0
	new_mat.albedo_color = Color(l, l, l)
	mesh.material_override = new_mat


func _process(delta):
	if Time.get_ticks_msec() >= init_time + delay:
		visible = true
		position.y = lerp(position.y, -0.5 if descending else target_y, delta * 4)
