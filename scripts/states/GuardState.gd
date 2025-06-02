class_name GuardState
extends State

var shield_effect: Node2D

func enter(_previous_state: String, _data: Dictionary = {}) -> void:
    var character = get_character()
    character.animation_player.play("guard") 
    character.is_guarding = true
    character.is_invincible = true
    
    # Create shield visual effect
    create_shield_effect(character)

func physics_update(delta: float) -> void:
    var character = get_character()
    var input = get_input()
    
    character.velocity.x = move_toward(character.velocity.x, 0, character.SPEED * 2)
    character.velocity += character.get_gravity() * delta
    character.move_and_slide()
    
    if input.is_action_released("guard"):
        transition_to("idle")
    # elif input.is_action_pressed("jump"):
    #     transition_to("air", {"air_source": "jump"})
    elif input.is_action_pressed("jab"):
        transition_to("attack", { "attack_type": "jab" })
    elif input.is_action_pressed("heavy_blow"):
        transition_to("attack", { "attack_type": "heavy_blow" })
    elif input.is_action_pressed("upper_cut"):
        transition_to("attack", { "attack_type": "uppercut" })
    elif input.is_action_pressed("grapple"):
        transition_to("grapple")
    elif input.is_action_pressed("dash"):
        transition_to("dash")

func create_shield_effect(character: CharacterBody2D) -> void:
    # Option 1: Sprite tint effect
    if character.animated_sprite:
        character.animated_sprite.modulate = Color(0.5, 0.5, 1.0, 0.8)  # Blue tint
    
    # Option 2: Shield circle overlay
    shield_effect = Node2D.new()
    character.add_child(shield_effect)
    
    # Create a circular shield sprite
    var shield_sprite = Sprite2D.new()
    shield_effect.add_child(shield_sprite)
    
    # Create a simple circle texture programmatically
    var image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
    var center = Vector2(32, 32)
    var radius = 30
    
    for x in range(64):
        for y in range(64):
            var distance = Vector2(x, y).distance_to(center)
            if distance <= radius and distance >= radius - 4:
                image.set_pixel(x, y, Color(0.2, 0.6, 1.0, 0.6))  # Blue shield edge
            elif distance <= radius - 4:
                image.set_pixel(x, y, Color(0.1, 0.3, 0.8, 0.2))  # Blue shield fill
    
    var texture = ImageTexture.new()
    texture.create_from_image(image)
    shield_sprite.texture = texture
    shield_sprite.position = Vector2(0, -16)  # Adjust position as needed
    
    # Add pulsing animation
    var tween = get_character().create_tween()
    tween.set_loops()
    tween.tween_property(shield_sprite, "scale", Vector2(1.1, 1.1), 0.5)
    tween.tween_property(shield_sprite, "scale", Vector2(1.0, 1.0), 0.5)

func exit():
    var character = get_character()
    character.is_guarding = false
    character.is_invincible = false
    
    # Remove shield visual effects
    remove_shield_effect(character)

func remove_shield_effect(character: CharacterBody2D) -> void:
    # Remove sprite tint
    if character.animated_sprite:
        character.animated_sprite.modulate = Color.WHITE
    
    # Remove shield overlay
    if shield_effect and is_instance_valid(shield_effect):
        shield_effect.queue_free()
        shield_effect = null
