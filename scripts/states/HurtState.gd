class_name HurtState
extends State

var hitstun_duration: float = 0.4
var elapsed_hitstun: float = 0.0
var damage_amount: int = 0
var is_guard_hit: bool = false
var is_guard_broken_by_grapple: bool = false

func enter(_previous_state: String, data: Dictionary = {}) -> void:
	var character = get_character()
	damage_amount = data.get("damage", 0)
	hitstun_duration = data.get("hitstun_duration", 0.4)
	is_guard_hit = data.get("is_guard_hit", false)
	is_guard_broken_by_grapple = data.get("is_guard_broken_by_grapple", false)
	
	elapsed_hitstun = 0.0
	
	character.animation_player.play("hurt")
	character.velocity = data.get("knockback", Vector2.ZERO)

	apply_damage(character, damage_amount) 
	character.is_invincible = true

func physics_update(delta: float) -> void:
	var character = get_character()
	elapsed_hitstun += delta
	
	character.velocity += character.get_gravity() * delta
	character.move_and_slide()
		
	if elapsed_hitstun >= hitstun_duration:
		var input = get_input()
		var input_direction_x = input.get_movement_axis()
		
		if character.is_on_floor():
			if is_equal_approx(input_direction_x, 0.0):
				transition_to("idle")
			else:
				transition_to("walking")
		else:
			transition_to("air", {"air_source": "knockback"})

func apply_damage(character: CharacterBody2D, amount: int) -> void:
	
	if amount <= 0 and not is_guard_broken_by_grapple:
		if not is_guard_hit and not is_guard_broken_by_grapple:
			return
		
	if character.is_in_group("players"):
		Globals.player_health -= amount
		if Globals.player_health <= 0:
			transition_to("dying") 
			return
	elif character.is_in_group("enemies"):
		Globals.enemy_health -= amount
		if Globals.enemy_health <= 0:
			transition_to("dying") 
			return

func exit() -> void:
	var character = get_character()
	character.is_invincible = false
