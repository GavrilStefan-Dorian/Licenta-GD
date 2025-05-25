class_name Idle
extends PlayerState

func enter(previous_state_path: String, data := {}) -> void:
	player.velocity.x = 0.0
	player.animation_player.play("idle")

func physics_update(_delta: float) -> void:
	player.velocity += player.get_gravity() * _delta
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
	elif Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
		finished.emit(WALKING)
