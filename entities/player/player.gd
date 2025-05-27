extends CharacterBody3D

signal set_movement_state(movement_state: MovementState)
signal set_movement_direction(movement_direction: Vector3)

@export var movement_states: Dictionary

var movement_direction: Vector3


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
			if Input.is_action_pressed("run"):
				set_movement_state.emit(movement_states["run"])
			else:
				set_movement_state.emit(movement_states["walk"])
		else:
			set_movement_state.emit(movement_states["idle"])


func _physics_process(_delta):
	if is_moving():
		set_movement_direction.emit(movement_direction)


func is_moving() -> bool:
	return abs(movement_direction.x) > 0 or abs(movement_direction.z) > 0
