class_name HitStunState
extends State

var hitstun_duration := 0.3
var elapsed := 0.0

func enter(_previous_state: String, data: Dictionary = {}) -> void:
    var character = get_character()
    character.animation_player.play("guard") # Reuse guard animation for hit reaction
    character.can_attack = false
    character.being_hit = true
    hitstun_duration = data.get("hitstun_duration", 0.3)
    elapsed = 0.0

func physics_update(delta: float) -> void:
    var character = get_character()
    elapsed += delta
    
    # Gradually slow down
    character.velocity.x = move_toward(character.velocity.x, 0, character.SPEED * 3)
    character.velocity += character.get_gravity() * delta
    character.move_and_slide()

    if elapsed >= hitstun_duration:
        transition_to("idle")

func exit():
    var character = get_character()
    character.can_attack = true
    character.being_hit = false