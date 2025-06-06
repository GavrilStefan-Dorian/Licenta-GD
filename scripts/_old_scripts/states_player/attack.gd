# class_name Attack
# extends PlayerState

# var attack_data: Dictionary
# var attack_type: String

# # duration is more damaging than useful, find other way of slowing down atks 
# var ATTACK_PRESETS = {
# 	"jab": {
# 		"damage": 5,
# 		"knockback": Vector2(150, -50), 
# 		"movement_factor": 0.3,
# 		"enemy_lift": 0
# 	},
# 	"heavy_blow": {
# 		"damage": 10,
# 		"knockback": Vector2(300, -100),
# 		"movement_factor": 0.1, 	
# 		"enemy_lift": 0
# 	},
# 	"uppercut": {
# 		"damage": 3,
# 		"knockback": Vector2(100, -300),
# 		"movement_factor": 0.3,
# 		"enemy_lift": 100  
# 	}
# }

# func enter(_previous_state_path: String, data := {}) -> void:
# 	player.can_attack = false
# 	attack_type = data.get("attack_type", "jab")
# 	attack_data = ATTACK_PRESETS[attack_type]
	
# 	player.animation_player.play("primary_attack")
# 	player.attack_timer = player.animation_player.get_animation("primary_attack").length
# 	player.current_attack_damage = attack_data.damage
# 	player.current_attack_knockback = attack_data.knockback
# 	player.current_enemy_lift = attack_data.enemy_lift

# 	# player.velocity.x = player.SPEED * attack_data.movement_factor * player.facing_direction # test if this does anything
# 	player.hitbox_config = HitBoxConfigurator.configure_hitbox(player, Vector2(50,50))


# func physics_update(delta: float) -> void:
# 	var input_direction_x := Input.get_axis("move_left", "move_right")
# 	# Movement during attack
# 	# player.velocity.x = move_toward(
# 	# 	player.velocity.x,
# 	# 	input_direction_x * player.SPEED * attack_data.movement_factor,
# 	# 	player.SPEED * delta 
# 	# )
# 	player.velocity += player.get_gravity() * delta
# 	player.move_and_slide()

# 	player.attack_timer -= delta
# 	if player.attack_timer > 0:
# 		return
		
# 	if Input.is_action_just_pressed("jump"):
# 		finished.emit(AIR)
# 	elif is_equal_approx(input_direction_x, 0.0):
# 		finished.emit(IDLE)
# 	elif Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
# 		finished.emit(WALKING)
	
			
# func exit():
# 	player.can_attack = true
# 	player.hitbox_config = HitBoxConfigurator.reset()
