extends Node

@export var animation_tree: AnimationTree
@export var player: CharacterBody3D

var tween: Tween
var on_floor_blend: float = 1
var on_floor_blend_target: float = 1


func _physics_process(delta):
	on_floor_blend_target = 1 if player.is_on_floor() else 0
	on_floor_blend = lerp(on_floor_blend, on_floor_blend_target, delta * 10)
	animation_tree.set("parameters/on_floor_blend/blend_amount", on_floor_blend)


func _on_set_movement_state(movement_state: MovementState):
	if tween:
		tween.kill()

	tween = create_tween()
	tween.tween_property(
		animation_tree, "parameters/movement_blend/blend_position", movement_state.id, 0.25
	)
	tween.parallel().tween_property(
		animation_tree, "parameters/movement_anim_speed/scale", movement_state.animation_speed, 0.7
	)


func _on_set_jump_state(jump_state: JumpState):
	animation_tree["parameters/" + jump_state.animation_name + "/request"] = (
		AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	)
