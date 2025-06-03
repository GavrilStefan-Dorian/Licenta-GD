class_name AttackState
extends State

var attack_data: Dictionary
var attack_type: String
var attack_timer: float = 0.0

var ATTACK_PRESETS = {
	"jab": {
		"damage": 5,
		"knockback": Vector2(150, -50), 
		"hitstun": 0.3,
		"recovery": 0.2,
		"guard_break": false,
		"enemy_lift": 0,
		"hitbox_size": Vector2(50, 50),
		"hitbox_offset": Vector2.ZERO
	},
	"heavy_blow": {
		"damage": 10,
		"knockback": Vector2(300, -100),
		"hitstun": 0.6,
		"recovery": 0.5,
		"guard_break": false,
		"enemy_lift": 0,
		"hitbox_size": Vector2(50, 50),
		"hitbox_offset": Vector2.ZERO
	},
	"uppercut": {
		"damage": 3,
		"knockback": Vector2(100, -300),
		"hitstun": 1.3,
		"recovery": 0.4,
		"guard_break": false,
		"enemy_lift": 100,
		"hitbox_size": Vector2(40, 40),
		"hitbox_offset": Vector2(10, -120)
	},
	 "fireball": {
		"damage": 8,
		"knockback": Vector2(200, -100),
		"hitstun": 0.4,
		"recovery": 0.5,
		"guard_break": false,
		"enemy_lift": 0,
		"projectile": true,
		"projectile_scene": "res://scenes/projectiles/fireball.tscn",
		"projectile_offset": Vector2(50, -20),
		"hitbox_size": Vector2(0, 0)  
	}
}
func spawn_projectile(character: CharacterBody2D, data: Dictionary) -> void:
	if not data.get("projectile", false):
		return
		
	var projectile_scene_path = data.get("projectile_scene", "")
	if projectile_scene_path.is_empty():
		return
		
	var projectile_scene = load(projectile_scene_path)
	if projectile_scene == null:
		return
		
	var projectile = projectile_scene.instantiate()
	if not projectile is Fireball:
		projectile.queue_free()
		return
		
	# Setup projectile
	projectile.damage = data.get("damage", 5)
	projectile.knockback = data.get("knockback", Vector2(100, -50))
	projectile.hitstun = data.get("hitstun", 0.3)
	projectile.direction = character.facing_direction
	projectile.source_character = character
	
	# Position the projectile
	var offset = data.get("projectile_offset", Vector2(30, -20))
	offset.x *= character.facing_direction
	projectile.global_position = character.global_position + offset
	
	# Add to scene
	character.get_tree().root.add_child(projectile)


func enter(_previous_state: String, data: Dictionary = {}) -> void:
	var character = get_character()
	character.can_attack = false # Should be handled by recovery timer
	attack_type = data.get("attack_type", "jab")
	attack_data = ATTACK_PRESETS[attack_type]
	
	character.animation_player.play("primary_attack")
	attack_timer = character.animation_player.get_animation("primary_attack").length
	
	if attack_data.get("projectile", false):
		# Schedule projectile spawning halfway through the animation
		var timer = character.get_tree().create_timer(attack_timer * 0.5)
		timer.timeout.connect(func(): spawn_projectile(character, attack_data))
		return
	
	character.current_attack_damage = attack_data.damage
	character.current_attack_knockback = attack_data.knockback
	character.current_hitstun_for_attack = attack_data.hitstun
	character.current_guard_break_for_attack = attack_data.get("guard_break", false)
	character.current_enemy_lift = attack_data.enemy_lift # Keep for now, might integrate into knockback
	character.attack_recovery_timer = attack_data.recovery
	
	if HitBoxConfigurator:
		character.hitbox_config = HitBoxConfigurator.configure_hitbox(character, attack_data.get("hitbox_size"), attack_data.get(("hitbox_offset")))

func physics_update(delta: float) -> void:
	var character = get_character()
	var input = get_input()
	
	var input_direction_x = input.get_movement_axis()
	
	character.velocity += character.get_gravity() * delta
	character.move_and_slide()

	attack_timer -= delta
	if character.attack_recovery_timer > 0:
		character.attack_recovery_timer -= delta
		# Character is in recovery, minimal movement control or none
		character.velocity.x = move_toward(character.velocity.x, 0, character.SPEED * 0.2) # e.g. reduced control
		return

	if attack_timer > 0: # Animation might still be playing for visual effect after recovery
		return
		
	# Recovery and animation finished, allow transitions
	# if input.is_action_pressed("jump"):
	# 	transition_to("air", {"air_source": "jump"})
	if is_equal_approx(input_direction_x, 0.0):
		transition_to("idle")
	elif input.is_movement_pressed():
		transition_to("walking")
	
func exit():
	var character = get_character()
	character.can_attack = true # Re-enable based on recovery logic elsewhere if needed
	if HitBoxConfigurator:
		character.hitbox_config = HitBoxConfigurator.reset()
