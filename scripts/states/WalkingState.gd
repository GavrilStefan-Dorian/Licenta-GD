class_name WalkingState
extends State

func enter(_previous_state: String, _data: Dictionary = {}) -> void:
	var character = get_character()
	character.animation_player.play("walking")

func physics_update(delta: float) -> void:
	var character = get_character()
	var input = get_input()
	
	var input_direction_x = input.get_movement_axis()
	if input_direction_x:
		character.velocity.x = input_direction_x * character.SPEED
	else:
		character.velocity.x = move_toward(character.velocity.x, 0, character.SPEED)
	
	character.velocity += character.get_gravity() * delta
	character.move_and_slide()
	
	if input.is_action_pressed("jump"):
		var direction = 0
		input_direction_x = input.get_movement_axis()
		if input_direction_x < 0:
			direction = -1
		elif input_direction_x > 0:
			direction = 1
		transition_to("air", {"air_source": "jump", "jump_direction": direction})
	elif input.is_action_pressed("jab"):
		transition_to("attack", { "attack_type": "jab" })
	elif input.is_action_pressed("heavy_blow"):
		transition_to("attack", { "attack_type": "heavy_blow" })
	elif input.is_action_pressed("upper_cut"):
		transition_to("attack", { "attack_type": "uppercut" })
	elif input.is_action_pressed("fireball"):
		transition_to("attack", {"attack_type": "fireball"})
	elif input.is_action_pressed("grapple"):
		transition_to("grapple")
	elif input.is_action_pressed("guard"):
		transition_to("guard")
	elif input.is_action_pressed("dash"):
		transition_to("dash")
	elif is_equal_approx(input_direction_x, 0.0):
		transition_to("idle")
