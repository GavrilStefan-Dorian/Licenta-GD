# class_name Dashing
# extends PlayerState

# var dash_timer: float

# func enter(previous_state_path: String, data := {}) -> void:
# 	player.can_dash = false
# 	player.animation_player.play("guard") 
# 	dash_timer = player.DASH_DURATION
	
# 	# Set dash velocity
# 	player.velocity.x = player.DASH_SPEED * player.facing_direction
	
# 	# Reset dash cooldown after delay
# 	player.get_tree().create_timer(1.0).timeout.connect(func(): player.can_dash = true)

# func physics_update(delta: float) -> void:
# 	# Don't apply gravity during dash for more control
# 	player.move_and_slide()
	
# 	dash_timer -= delta
	
# 	if dash_timer > 0:
# 		return
		
# 	var input_direction_x := Input.get_axis("move_left", "move_right")
	
# 	if Input.is_action_just_pressed("jump"):
# 		finished.emit(AIR)
# 	elif Input.is_action_just_pressed("jab"):
# 		finished.emit(ATTACK, { "attack_type": "jab" })
# 	elif Input.is_action_just_pressed("heavy_blow"):
# 		finished.emit(ATTACK, { "attack_type": "heavy_blow" })
# 	elif Input.is_action_just_pressed("upper_cut"):
# 		finished.emit(ATTACK, { "attack_type": "uppercut" })
# 	elif Input.is_action_just_pressed("grapple"):
# 		finished.emit(GRAPPLE)
# 	elif Input.is_action_just_pressed("guard"):
# 		finished.emit(GUARD)
# 	elif Input.is_action_just_pressed("dash"):
# 		finished.emit(DASH)
# 	elif is_equal_approx(input_direction_x, 0.0):
# 		finished.emit(IDLE)
# 	elif Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
# 		finished.emit(WALKING)
		
			
# func exit():
# 	pass
