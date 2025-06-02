class_name HurtState
extends State

var hurt_duration := 0.4
var elapsed := 0.0
var damage_amount := 0

func enter(_previous_state: String, data: Dictionary = {}) -> void:
    var character = get_character()
    damage_amount = data.get("damage", 0)
    elapsed = 0.0
    
    character.velocity = data.get("knockback", Vector2.ZERO)

    apply_damage(character, damage_amount)
    
    character.animation_player.play("hurt")      
    character.is_invincible = true

func physics_update(delta: float) -> void:
    var character = get_character()
    elapsed += delta
    
    character.velocity += character.get_gravity() * delta
    character.move_and_slide()
    
    # character.velocity.x = move_toward(character.velocity.x, 0, character.SPEED * 2)
    
    if elapsed >= hurt_duration:
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
    if character.is_invincible or character.is_guarding:
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
