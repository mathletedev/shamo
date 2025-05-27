extends Node

@export var player: CharacterBody3D

@onready var yaw_node := $Yaw
@onready var pitch_node := $Yaw/Pitch
@onready var spring_arm := $Yaw/Pitch/SpringArm3D
@onready var camera := $Yaw/Pitch/SpringArm3D/Camera3D

var yaw: float = 0
var pitch: float = 0

var yaw_sensitivity: float = 0.07
var pitch_sensitivity: float = 0.07
var yaw_acceleration: float = 15
var pitch_acceleration: float = 15

var pitch_max: float = 75
var pitch_min: float = -55

var tween: Tween


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	spring_arm.add_excluded_object(player.get_rid())


func _input(event):
	if event is InputEventMouseMotion:
		yaw += -event.relative.x * yaw_sensitivity
		pitch += event.relative.y * pitch_sensitivity


func _physics_process(delta):
	pitch = clamp(pitch, pitch_min, pitch_max)

	yaw_node.rotation_degrees.y = lerp(yaw_node.rotation_degrees.y, yaw, yaw_acceleration * delta)
	pitch_node.rotation_degrees.x = lerp(
		pitch_node.rotation_degrees.x, pitch, pitch_acceleration * delta
	)


func _on_set_movement_state(movement_state: MovementState):
	if tween:
		tween.kill()

	tween = create_tween()
	(
		tween
		. tween_property(camera, "fov", movement_state.camera_fov, 0.5)
		. set_trans(Tween.TRANS_SINE)
		. set_ease(Tween.EASE_OUT)
	)
