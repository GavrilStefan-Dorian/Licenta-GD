class_name Grapple
extends PlayerState

func enter(previous_state_path: String, data := {}) -> void:
	player.can_attack = false
	player.animation_player.play("primary_attack")
	player.attack_timer = 0.5
	
	# Grapple has special logic - check for enemies in range
	perform_grapple()

func perform_grapple():
	var space_state = player.get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		player.position,
		player.position + Vector2(150, 0)
	)
	var result = space_state.intersect_ray(query)
	print("Grapple ray result: ", result)

	
	if result and result.collider.is_in_group("enemies"):
		var enemy = result.collider
		
		# Pull enemy towards player
		if enemy.has_method("apply_knockback"):
			var pull_force = Vector2(-200, -50)
			enemy.apply_knockback(pull_force)
		
		# Deal damage after delay
		await player.get_tree().create_timer(0.2).timeout
		if enemy and is_instance_valid(enemy):
			if enemy.has_method("take_damage"):
				enemy.take_damage(4)
			# Then push away
			if enemy.has_method("apply_knockback"):
				enemy.apply_knockback(Vector2(300, -100))

func physics_update(delta: float) -> void:
	var input_direction_x := Input.get_axis("move_left", "move_right")
	
	# No movement during grapple
	player.velocity.x = move_toward(player.velocity.x, 0, player.SPEED * 3)
	player.velocity += player.get_gravity() * delta
	player.move_and_slide()
	
	player.attack_timer -= delta
	if player.attack_timer > 0:
		return
	
	if Input.is_action_just_pressed("jump"):
		finished.emit(AIR)
	elif Input.is_action_just_pressed("jab"):
		finished.emit(ATTACK, { "attack_type": "jab" })
	elif Input.is_action_just_pressed("heavy_blow"):
		finished.emit(ATTACK, { "attack_type": "heavy_blow" })
	elif Input.is_action_just_pressed("upper_cut"):
		finished.emit(ATTACK, { "attack_type": "uppercut" })
	elif Input.is_action_just_pressed("guard"):
		finished.emit(GUARD)
	elif Input.is_action_just_pressed("dash"):
		finished.emit(DASH)
	elif is_equal_approx(input_direction_x, 0.0):
		finished.emit(IDLE)
	elif Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
		finished.emit(WALKING)


func exit():
	player.can_attack = true
