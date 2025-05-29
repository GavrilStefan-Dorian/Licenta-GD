# class_name Grapple
# extends PlayerState

# const grapple_pull_force: Vector2 = Vector2(-200, -50)
# const grapple_push_force: Vector2 = Vector2(300, -100)

# func grapple_behavior(character: CharacterBody2D) -> Callable:
# 	return func(target):
# 		if target.has_method("apply_knockback"):
# 			# Pull phase
# 			var pull = grapple_pull_force
# 			pull.x *= character.facing_direction
# 			target.apply_knockback(pull)
			
# 			# Push phase after delay
# 			await character.get_tree().create_timer(0.2).timeout
# 			if is_instance_valid(target):
# 				var push = grapple_push_force
# 				push.x *= character.facing_direction
# 				target.apply_knockback(push)

# func enter(_previous_state_path: String, _data := {}) -> void:
# 	player.can_attack = false
# 	player.animation_player.play("primary_attack")
# 	player.attack_timer = 0.5
	
# 	player.hitbox_config = HitBoxConfigurator.configure_hitbox(player, Vector2(100, 50), grapple_behavior)


# func physics_update(delta: float) -> void:
# 	var input_direction_x := Input.get_axis("move_left_player", "move_right_player")

# 	player.velocity.x = move_toward(player.velocity.x, 0, player.SPEED * 3)
# 	player.velocity += player.get_gravity() * delta
# 	player.move_and_slide()
	
# 	player.attack_timer -= delta
# 	if player.attack_timer > 0:
# 		return
	
# 	if Input.is_action_just_pressed("jump_player"):
# 		finished.emit(AIR)
# 	elif Input.is_action_just_pressed("jab_player"):
# 		finished.emit(ATTACK, { "attack_type": "jab" })
# 	elif Input.is_action_just_pressed("heavy_blow_player"):
# 		finished.emit(ATTACK, { "attack_type": "heavy_blow" })
# 	elif Input.is_action_just_pressed("upper_cut_player"):
# 		finished.emit(ATTACK, { "attack_type": "uppercut" })
# 	elif Input.is_action_just_pressed("guard_player"):
# 		finished.emit(GUARD)
# 	elif Input.is_action_just_pressed("dash_player"):
# 		finished.emit(DASH)
# 	elif is_equal_approx(input_direction_x, 0.0):
# 		finished.emit(IDLE)
# 	elif Input.is_action_pressed("move_left_player") or Input.is_action_pressed("move_right_player"):
# 		finished.emit(WALKING)
# func exit():
# 	player.can_attack = true
# 	player.hitbox_config = HitBoxConfigurator.reset()
