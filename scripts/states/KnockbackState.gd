class_name KnockbackState
extends State

var knockback_duration := 0.8
var elapsed := 0.0

func enter(_previous_state: String, data: Dictionary = {}) -> void:
	var character = get_character()
	character.velocity = data.get("knockback_velocity", Vector2.ZERO)
	elapsed = 0.0

func physics_update(delta: float) -> void:
	var character = get_character()
	elapsed += delta
	character.velocity += character.get_gravity() * delta
	character.move_and_slide()

	if elapsed >= knockback_duration:
		transition_to("idle")