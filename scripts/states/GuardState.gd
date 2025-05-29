class_name GuardState
extends State

func enter(_previous_state: String, _data: Dictionary = {}) -> void:
	var character = get_character()
	character.animation_player.play("guard") 
	character.is_guarding = true
	character.is_invincible = true

func physics_update(delta: float) -> void:
	var character = get_character()
	var input = get_input()
	
	character.velocity.x = move_toward(character.velocity.x, 0, character.SPEED * 2)
	character.velocity += character.get_gravity() * delta
	character.move_and_slide()
	
	if not input.is_action_pressed("guard"):
		transition_to("idle")
	elif input.is_action_pressed("jump"):
		transition_to("air")
	elif input.is_action_pressed("jab"):
		transition_to("attack", { "attack_type": "jab" })
	elif input.is_action_pressed("heavy_blow"):
		transition_to("attack", { "attack_type": "heavy_blow" })
	elif input.is_action_pressed("upper_cut"):
		transition_to("attack", { "attack_type": "uppercut" })
	elif input.is_action_pressed("grapple"):
		transition_to("grapple")
	elif input.is_action_pressed("dash"):
		transition_to("dash")

func exit():
	var character = get_character()
	character.is_guarding = false
	character.is_invincible = false
