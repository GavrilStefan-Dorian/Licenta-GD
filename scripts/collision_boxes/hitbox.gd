class_name HitBox
extends Area2D

func _init() -> void:
	collision_layer = 1 << 4
	collision_mask = 1 << 5

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if !area.is_in_group("hurtboxes"):
		return
		
	var hurtbox = area
	var target = hurtbox.owner
	var attacker = owner
	
	if !target or !is_instance_valid(target) or !attacker or !is_instance_valid(attacker):
		return
	
	if target == attacker:
		return
		
	if !attacker.hitbox_config.is_active:
		return
	
	var target_controller = target.get_node("StateMachineController")
	if !target_controller:
		return

	if attacker.hitbox_config.get("is_grapple", false):
		if attacker.hitbox_config.special_behavior:
			attacker.hitbox_config.special_behavior.call(target)
		return

	if target.is_guarding:
		target_controller.state_machine.transition_to("hurt", {
			"damage": 0,
			"knockback": Vector2(20 * attacker.facing_direction, 0), 
			"hitstun_duration": target.GUARD_STUN_DURATION,
			"is_guard_hit": true
		})
		return

	if target.is_invincible: 
		return

	if attacker.hitbox_config.damage > 0 or attacker.hitbox_config.knockback != Vector2.ZERO:
		var knockback_force = attacker.hitbox_config.knockback
		knockback_force.x *= attacker.facing_direction
		
		target_controller.state_machine.transition_to("hurt", {
			"damage": attacker.hitbox_config.damage,
			"knockback": knockback_force,
			"hitstun_duration": attacker.hitbox_config.get("hitstun_duration", 0.3) # Default if not set
		})
	
	if attacker.hitbox_config.special_behavior and not attacker.hitbox_config.get("is_grapple", false):
		attacker.hitbox_config.special_behavior.call(target)
