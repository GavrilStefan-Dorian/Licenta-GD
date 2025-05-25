class_name Guard
extends PlayerState

func enter(previous_state_path: String, data := {}) -> void:
	player.animation_player.play("guard")  # Or guard animation
	player.is_guarding = true
	player.is_invincible = true

func physics_update(delta: float) -> void:
	# Stop movement while guarding
	player.velocity.x = move_toward(player.velocity.x, 0, player.SPEED * 2)
	player.velocity += player.get_gravity() * delta
	player.move_and_slide()
	
	# Exit guard when button released or other inputs
	if Input.is_action_just_released("guard"):
		finished.emit(IDLE)
	elif Input.is_action_just_pressed("jump"):
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

func exit():
	player.is_guarding = false
	player.is_invincible = false
