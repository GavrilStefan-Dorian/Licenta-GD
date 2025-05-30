class_name HurtState
extends State

var hurt_duration := 0.3  # Short duration to not interrupt gameplay too much
var elapsed := 0.0
var damage_amount := 0

func enter(_previous_state: String, data: Dictionary = {}) -> void:
    var character = get_character()
    damage_amount = data.get("damage", 0)
    elapsed = 0.0
    
    # Apply damage
    apply_damage(character, damage_amount)
    
    # Play hurt animation
    character.animation_player.play("hurt")  # Make sure you have this animation
    
    # Brief invincibility
    character.is_invincible = true

func physics_update(delta: float) -> void:
    var character = get_character()
    elapsed += delta
    
    # Apply gravity and movement
    character.velocity += character.get_gravity() * delta
    character.move_and_slide()
    
    # Gradually reduce horizontal velocity
    character.velocity.x = move_toward(character.velocity.x, 0, character.SPEED * 2)
    
    if elapsed >= hurt_duration:
        # Return to appropriate state based on input/situation
        var input = get_input()
        var input_direction_x = input.get_movement_axis()
        
        if character.is_on_floor():
            if is_equal_approx(input_direction_x, 0.0):
                transition_to("idle")
            else:
                transition_to("walking")
        else:
            transition_to("air")

func apply_damage(character: CharacterBody2D, amount: int) -> void:
    if character.is_invincible or character.is_guarding:
        return
        
    if character.is_in_group("players"):
        Globals.player_health -= amount
        if Globals.player_health <= 0:
            handle_player_death()
    elif character.is_in_group("enemies"):
        Globals.enemy_health -= amount
        if Globals.enemy_health <= 0:
            handle_enemy_death()

func handle_player_death() -> void:
    Globals.enemy_wins += 1
    if Globals.enemy_wins >= ceil(Globals.MAX_ROUNDS / 2.0):
        Globals.emit_signal("match_ended", "enemy")
    else:
        Globals.emit_signal("round_ended", "enemy")
    get_character().queue_free()

func handle_enemy_death() -> void:
    Globals.player_wins += 1
    if Globals.player_wins >= ceil(Globals.MAX_ROUNDS / 2.0):
        Globals.emit_signal("match_ended", "player")
    else:
        Globals.emit_signal("round_ended", "player")
    get_character().queue_free()

func exit() -> void:
    var character = get_character()
    character.is_invincible = false