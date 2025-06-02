class_name IdleState
extends State

func enter(_previous_state: String, _data: Dictionary = {}) -> void:
	var character = get_character()
	character.velocity.x = 0.0
	character.animation_player.play("idle")

func physics_update(delta: float) -> void:
	var character = get_character()
	var input = get_input()
	
	character.velocity += character.get_gravity() * delta
	character.move_and_slide()

	if input.is_action_pressed("jump"):
		var direction = 0
		var input_direction_x = input.get_movement_axis() 
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
	elif input.is_action_pressed("grapple"):
		transition_to("grapple")
	elif input.is_action_pressed("guard"):
		transition_to("guard")
	elif input.is_action_pressed("dash"):
		transition_to("dash")
	elif input.is_movement_pressed():
		transition_to("walking")