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
	
	if target.is_invincible or target.is_guarding:
		return
	
	if attacker.hitbox_config.damage > 0 or attacker.hitbox_config.knockback != Vector2.ZERO:
		var knockback = attacker.hitbox_config.knockback
		knockback.x *= attacker.facing_direction
		target_controller.state_machine.transition_to("hurt", {
			"damage": attacker.hitbox_config.damage,
			"knockback": knockback
		})
	
	if attacker.hitbox_config.special_behavior:
		attacker.hitbox_config.special_behavior.call(target)
