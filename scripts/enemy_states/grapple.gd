class_name GrappleEnemy
extends EnemyState

func enter(previous_state_path: String, data := {}) -> void:
	enemy.can_attack = false
	enemy.animation_player.play("primary_attack")
	enemy.attack_timer = 0.5
	
	# Grapple has special logic - check for enemies in range
	perform_grapple()

func perform_grapple():
	var space_state = enemy.get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(
		enemy.position,
		enemy.position + Vector2(enemy.facing_direction * 150, 0)
	)
	var result = space_state.intersect_ray(query)
	print("Grapple ray result: ", result)

	
	if result and result.collider.is_in_group("players"):
		var enemy = result.collider
		
		# Pull enemy towards enemy
		if enemy.has_method("apply_knockback"):
			var pull_force = Vector2(-200, -50)
			enemy.apply_knockback(pull_force)
		
		# Deal damage after delay
		await enemy.get_tree().create_timer(0.2).timeout
		if enemy and is_instance_valid(enemy):
			if enemy.has_method("take_damage"):
				enemy.take_damage(4)
			# Then push away
			if enemy.has_method("apply_knockback"):
				enemy.apply_knockback(Vector2(300, -100))

func physics_update(delta: float) -> void:
	var input_direction_x := Input.get_axis("move_left_enemy", "move_right_enemy")
	
	# No movement during grapple
	enemy.velocity.x = move_toward(enemy.velocity.x, 0, enemy.SPEED * 3)
	enemy.velocity += enemy.get_gravity() * delta
	enemy.move_and_slide()
	
	enemy.attack_timer -= delta
	if enemy.attack_timer > 0:
		return
	
	if Input.is_action_just_pressed("jump_enemy"):
		finished.emit(AIR)
	elif Input.is_action_just_pressed("jab_enemy"):
		finished.emit(ATTACK, { "attack_type": "jab" })
	elif Input.is_action_just_pressed("heavy_blow_enemy"):
		finished.emit(ATTACK, { "attack_type": "heavy_blow" })
	elif Input.is_action_just_pressed("upper_cut_enemy"):
		finished.emit(ATTACK, { "attack_type": "uppercut" })
	elif Input.is_action_just_pressed("guard_enemy"):
		finished.emit(GUARD)
	elif Input.is_action_just_pressed("dash_enemy"):
		finished.emit(DASH)
	elif is_equal_approx(input_direction_x, 0.0):
		finished.emit(IDLE)
	elif Input.is_action_pressed("move_left_enemy") or Input.is_action_pressed("move_right_enemy"):
		finished.emit(WALKING)


func exit():
	enemy.can_attack = true
