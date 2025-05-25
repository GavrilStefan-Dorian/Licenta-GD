class_name Walking
extends PlayerState

func enter(previous_state_path: String, data := {}) -> void:
	player.animation_player.play("walking")

func physics_update(delta: float) -> void:
	var input_direction_x := Input.get_axis("move_left", "move_right")
	if input_direction_x:
		player.velocity.x = input_direction_x * player.SPEED
		#animated_sprite.flip_h = direction < 0 	
	else:
		player.velocity.x = move_toward(input_direction_x, 0, player.SPEED)
	player.velocity += player.get_gravity() * delta
	
	player.velocity += player.get_gravity() * delta
	player.move_and_slide()
	
	if Input.is_action_just_pressed("jump"):
		finished.emit(AIR)
	elif Input.is_action_just_pressed("jab"):
		finished.emit(ATTACK, { "attack_type": "jab" })
	elif Input.is_action_just_pressed("heavy_blow"):
		finished.emit(ATTACK, { "attack_type": "heavy_blow" })
	elif Input.is_action_just_pressed("upper_cut"):
		finished.emit(ATTACK, { "attack_type": "uppercut" })
	elif Input.is_action_just_pressed("grapple"):
		finished.emit(GRAPPLE)
	elif Input.is_action_just_pressed("guard"):
		finished.emit(GUARD)
	elif Input.is_action_just_pressed("dash"):
		finished.emit(DASH)
	elif is_equal_approx(input_direction_x, 0.0):
		finished.emit(IDLE)
