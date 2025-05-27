extends Node

@export var player: CharacterBody3D
@export var mesh_root: Node3D
@export var rotation_speed: float = 8
@export var fall_gravity: float = 45

var direction: Vector3
var velocity: Vector3
var acceleration: float
var speed: float
var jump_gravity := fall_gravity


func _physics_process(delta):
	velocity.x = speed * direction.normalized().x
	velocity.z = speed * direction.normalized().z

	if not player.is_on_floor():
		if velocity.y >= 0:
			velocity.y -= jump_gravity * delta
		else:
			velocity.y -= fall_gravity * delta

	player.velocity = player.velocity.lerp(velocity, acceleration * delta)
	player.move_and_slide()

	var target_rotation = atan2(direction.x, direction.z) - player.rotation.y
	mesh_root.rotation.y = lerp_angle(mesh_root.rotation.y, target_rotation, rotation_speed * delta)


func _on_set_movement_state(movement_state: MovementState):
	speed = movement_state.speed
	acceleration = movement_state.acceleration


func _on_set_movement_direction(movement_direction: Vector3):
	direction = movement_direction


func _on_set_jump_state(jump_state: JumpState):
	if jump_state.jump_height == 0:
		return

	velocity.y = 2 * jump_state.jump_height / jump_state.apex_duration
	jump_gravity = velocity.y / jump_state.apex_duration
