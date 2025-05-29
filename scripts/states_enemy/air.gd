class_name AirEnemy
extends EnemyState

func enter(_previous_state_path: String, _data := {}) -> void:
	enemy.velocity.y = enemy.JUMP_VELOCITY
	#enemy.animation_enemy.play("jump")

func physics_update(delta: float) -> void:
	var input_direction_x := Input.get_axis("move_left_enemy", "move_right_enemy")
	if input_direction_x:
		enemy.velocity.x = input_direction_x * enemy.SPEED
		#animated_sprite.flip_h = direction < 0 	
	else:
		enemy.velocity.x = move_toward(input_direction_x, 0, enemy.SPEED)
	enemy.velocity += enemy.get_gravity() * delta
	
	enemy.move_and_slide()
	

	if enemy.is_on_floor():
		if is_equal_approx(input_direction_x, 0.0):
			finished.emit(IDLE)
		else:
			finished.emit(WALKING)
	elif Input.is_action_just_pressed("jab_enemy"):
		finished.emit(ATTACK, { "attack_type": "jab" })
	elif Input.is_action_just_pressed("heavy_blow_enemy"):
		finished.emit(ATTACK, { "attack_type": "heavy_blow" })
	elif Input.is_action_just_pressed("upper_cut_enemy"):
		finished.emit(ATTACK, { "attack_type": "uppercut" })
	elif Input.is_action_just_pressed("grapple_enemy"):
		finished.emit(GRAPPLE)
	elif Input.is_action_just_pressed("guard_enemy"):
		finished.emit(GUARD)
	elif Input.is_action_just_pressed("dash_enemy"):
		finished.emit(DASH)
