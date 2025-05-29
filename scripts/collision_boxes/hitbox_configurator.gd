class_name HitBoxConfigurator
extends Node

static func position_hitbox(character: CharacterBody2D, size: Vector2) -> void:
	var hitbox_shape = character.hitbox.get_node("HitBoxShape")
	var collision_shape = character.get_node("PhysicsCollision")
	
	var collision_extent = collision_shape.shape.radius + 1 # Slight offset to not overlap collision shape
	hitbox_shape.position.x = (collision_extent + size.x / 2) * character.facing_direction
	hitbox_shape.position.y = size.y

static func configure_hitbox(character: CharacterBody2D, size: Vector2, special_behavior: Callable = Callable()) -> Dictionary:
	position_hitbox(character, size) 
	
	return {
		"is_active": true,
		"damage": character.current_attack_damage,
		"immediate_knockback": character.current_attack_knockback,
		"special_behavior": special_behavior.call(character) if special_behavior.is_valid() else null
	}

static func reset() -> Dictionary:
	return {
		"is_active": false,
		"is_grapple": false,
		"damage": 0,
		"immediate_knockback": Vector2.ZERO,
		"special_behavior": null
	}