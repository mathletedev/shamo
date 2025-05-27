extends CharacterBody3D

signal set_movement_state(movement_state: MovementState)
signal set_movement_direction(movement_direction: Vector3)
signal set_jump_state(jump_state: JumpState)

@export var max_jumps: int = 2
@export var movement_states: Dictionary
@export var jump_states: Dictionary

var movement_direction: Vector3
var jump_counter: int = 0
var landed: bool = true


func _ready():
	set_movement_state.emit(movement_states["idle"])


func _input(event):
	if event.is_action("movement"):
		movement_direction.x = (
			Input.get_action_strength("left") - Input.get_action_strength("right")
		)
		movement_direction.z = (
			Input.get_action_strength("forwards") - Input.get_action_strength("backwards")
		)

		if is_moving():
			if Input.is_action_pressed("sprint"):
				set_movement_state.emit(movement_states["sprint"])
			else:
				if Input.is_action_pressed("walk"):
					set_movement_state.emit(movement_states["walk"])
				else:
					set_movement_state.emit(movement_states["run"])
		else:
			set_movement_state.emit(movement_states["idle"])


func _physics_process(_delta):
	if is_moving():
		set_movement_direction.emit(movement_direction)

	if is_on_floor():
		jump_counter = 0

		if not landed:
			landed = true
			set_jump_state.emit(jump_states["land"])
	else:
		landed = false

		if jump_counter == 0:
			jump_counter = 1

	if jump_counter < max_jumps:
		if Input.is_action_just_pressed("jump"):
			var jump_name = "ground_jump" if jump_counter == 0 else "air_jump"

			set_jump_state.emit(jump_states[jump_name])
			jump_counter += 1


func is_moving() -> bool:
	return abs(movement_direction.x) > 0 or abs(movement_direction.z) > 0
