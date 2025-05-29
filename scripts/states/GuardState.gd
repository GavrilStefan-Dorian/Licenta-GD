class_name GuardState
extends State

func enter(_previous_state: String, _data: Dictionary = {}) -> void:
	var character = get_character()
	character.animation_player.play("guard") 
	character.is_guarding = true
	character.guard_damage_reduction = 0.5

func physics_update(delta: float) -> void:
	var character = get_character()
	var input = get_input()
	
	character.velocity.x = move_toward(character.velocity.x, 0, character.SPEED * 2)
	character.velocity += character.get_gravity() * delta
	character.move_and_slide()
	
	if not input.is_action_pressed("guard") and not character.being_hit:
		transition_to("idle")

func exit():
	var character = get_character()
	character.is_guarding = false
	character.guard_damage_reduction = 1.0 
