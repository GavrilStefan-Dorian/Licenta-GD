class_name DyingState
extends State

var death_animation_duration: float = 1.0
var elapsed: float = 0.0

func enter(_previous_state: String, data: Dictionary = {}) -> void:
    var character = get_character()
    
    character.animation_player.play("dying")
    
    character.is_invincible = true
    character.can_attack = false
    character.can_dash = false
    
    character.velocity = Vector2.ZERO    
    elapsed = 0.0

func physics_update(delta: float) -> void:
    var character = get_character()
    elapsed += delta
    
    character.velocity += character.get_gravity() * delta
    character.move_and_slide()
    
    if elapsed >= death_animation_duration:
        handle_death(character)

func handle_death(character: CharacterBody2D) -> void:
    if character.is_in_group("players"):
        Globals.enemy_wins += 1
        if Globals.enemy_wins >= ceil(Globals.MAX_ROUNDS / 2.0):
            Globals.match_ended.emit("enemy")
        else:
            Globals.round_ended.emit("enemy")
    elif character.is_in_group("enemies"):
        Globals.player_wins += 1
        if Globals.player_wins >= ceil(Globals.MAX_ROUNDS / 2.0):
            Globals.match_ended.emit("player")
        else:
            Globals.round_ended.emit("player")
    
    character.queue_free()

func exit() -> void:
    pass