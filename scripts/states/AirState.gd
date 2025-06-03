class_name AirState
extends State

const JUMP_VELOCITY_Y = -550.0
const JUMP_VELOCITY_X = 0.0
const JUMP_ARC_X = 250.0

func enter(_previous_state: String, _data: Dictionary = {}) -> void:
	var character = get_character()
	var air_source = _data.get("air_source", "jump")  # "jump" or "knockback"

	if air_source == "jump":
		var jump_direction = _data.get("jump_direction", 0)
		character.velocity.y = JUMP_VELOCITY_Y
		if jump_direction == 0:
			character.velocity.x = JUMP_VELOCITY_X
		else:
			character.velocity.x = JUMP_ARC_X * jump_direction
		character.facing_direction = jump_direction if jump_direction != 0 else character.facing_direction

func physics_update(delta: float) -> void:
	var character = get_character()
	var input = get_input()

	character.velocity += character.get_gravity() * delta * 1.2
	character.move_and_slide()

	if character.is_on_floor():
		var input_direction_x = input.get_movement_axis()
		if is_equal_approx(input_direction_x, 0.0):
			transition_to("idle")
		else:
			transition_to("walking")

	elif input.is_action_pressed("jab") and character.can_attack:
		transition_to("air_attack", {"attack_type": "air_jab"})
	elif input.is_action_pressed("heavy_blow") and character.can_attack:
		transition_to("air_attack", {"attack_type": "air_heavy"})
	elif input.is_action_pressed("upper_cut") and character.can_attack:
		transition_to("air_attack", {"attack_type": "air_uppercut"})
