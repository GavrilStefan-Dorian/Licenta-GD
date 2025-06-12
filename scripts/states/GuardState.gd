class_name GuardState
extends State

var shield_effect: Node2D
var tween : Tween = null

func enter(_previous_state: String, _data: Dictionary = {}) -> void:
    var character = get_character()
    character.animation_player.play("guard") 
    character.is_guarding = true
    character.is_invincible = true
    
    create_shield_effect(character)

func physics_update(delta: float) -> void:
    var character = get_character()
    var input = get_input()
    
    character.velocity.x = move_toward(character.velocity.x, 0, character.SPEED * 0.5) # Slower movement while guarding
    character.velocity += character.get_gravity() * delta
    character.move_and_slide()
    
    if input.is_action_released("guard"):
        transition_to("idle")

func create_shield_effect(character: CharacterBody2D) -> void:
    if character.animated_sprite:
        character.animated_sprite.modulate = Color(0.5, 0.5, 1.0, 0.8) 
    
    shield_effect = Node2D.new()
    character.add_child(shield_effect)
    
    var shield_sprite = Sprite2D.new()
    shield_effect.add_child(shield_sprite)
    
    const w = 100
    const h = 140
    var image = Image.create(w, h, false, Image.FORMAT_RGBA8)
    var center = Vector2(50, 70)
    var radius_x = 50 
    var radius_y = 70
    var border_thickness = 0.15  
    
    for x in range(w):
        for y in range(h):
            var dx = x - center.x
            var dy = y - center.y
            var elliptical_value = (dx * dx) / (radius_x * radius_x) + (dy * dy) / (radius_y * radius_y)
            
            if elliptical_value <= 1.0 and elliptical_value >= (1.0 - border_thickness):
                image.set_pixel(x, y, Color(0.2, 0.6, 1.0, 0.6))
            elif elliptical_value <= 1.0 - border_thickness:
                image.set_pixel(x, y, Color(0.1, 0.3, 0.8, 0.2))
    
    var texture = ImageTexture.new()
    texture = ImageTexture.create_from_image(image)
    shield_sprite.texture = texture
    shield_sprite.position = Vector2(0, -16)  
    
    tween = get_character().create_tween()
    tween.set_loops()
    tween.tween_property(shield_sprite, "scale", Vector2(1.1, 1.1), 0.5)
    tween.tween_property(shield_sprite, "scale", Vector2(1.0, 1.0), 0.5)

func exit():
    var character = get_character()
    character.is_guarding = false
    character.is_invincible = false
    
    tween.kill()
    tween = null

    remove_shield_effect(character)

func remove_shield_effect(character: CharacterBody2D) -> void:
    if character.animated_sprite:
        character.animated_sprite.modulate = Color.WHITE
    
    if shield_effect and is_instance_valid(shield_effect):
        shield_effect.queue_free()
        shield_effect = null
