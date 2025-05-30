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
    
    # Don't hit yourself
    if target == attacker:
        return
        
    # Check if hitbox is active
    if !attacker.hitbox_config.is_active:
        return
    
    var target_controller = target.get_node("StateMachineController")
    if !target_controller:
        return
    
    # Check if target is invincible or guarding
    if target.is_invincible or target.is_guarding:
        return
    
    # Apply damage through hurt state
    if attacker.hitbox_config.damage > 0:
        target_controller.state_machine.transition_to("hurt", {
            "damage": attacker.hitbox_config.damage
        })
    
    # Apply knockback through knockback state
    if attacker.hitbox_config.immediate_knockback != Vector2.ZERO:
        var knockback = attacker.hitbox_config.immediate_knockback
        knockback.x *= attacker.facing_direction
        target_controller.state_machine.transition_to("knockback", {
            "knockback_velocity": knockback
        })
    
    # Handle special behaviors (like grapple)
    if attacker.hitbox_config.special_behavior:
        attacker.hitbox_config.special_behavior.call(target)


