class_name HitBoxConfigurator
extends Node

static func position_hitbox(character: CharacterBody2D, size: Vector2, offset: Vector2 = Vector2.ZERO) -> void:
	var hitbox_shape = character.hitbox.get_node("HitBoxShape")
	var collision_shape = character.get_node("PhysicsCollision")
	
	var collision_extent = collision_shape.shape.radius + 1 # Slight offset to not overlap collision shape
	hitbox_shape.shape.size.x = size.x
	hitbox_shape.shape.size.y = size.y
	hitbox_shape.position.x = (collision_extent + size.x / 2) * character.facing_direction + (offset.x * character.facing_direction)
	hitbox_shape.position.y = size.y + offset.y

static func configure_hitbox(character: CharacterBody2D, size: Vector2, offset: Vector2, special_behavior: Callable = Callable(), is_grapple_flag: bool = false) -> Dictionary:
	position_hitbox(character, size, offset) 
	
	return {
		"is_active": true,
		"is_grapple": is_grapple_flag,
		"damage": character.current_attack_damage,
		"knockback": character.current_attack_knockback,
		"special_behavior": special_behavior.call(character) if special_behavior.is_valid() else null,
		"hitstun_duration": character.current_hitstun_for_attack,
		"guard_break": character.current_guard_break_for_attack
	}

static func reset() -> Dictionary:
	return {
		"is_active": false,
		"is_grapple": false,
		"damage": 0,
		"knockback": Vector2.ZERO,
		"special_behavior": null,
		"hitstun_duration": 0.0,
		"guard_break": false
	}
