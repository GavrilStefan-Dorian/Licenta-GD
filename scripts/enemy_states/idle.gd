class_name IdleEnemy
extends EnemyState

func enter(previous_state_path: String, data := {}) -> void:
	enemy.velocity.x = 0.0
	enemy.animation_player.play("idle")

func physics_update(_delta: float) -> void:
	enemy.velocity += enemy.get_gravity() * _delta
	enemy.move_and_slide()

	if Input.is_action_just_pressed("jump_enemy"):
		finished.emit(AIR)
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
	elif Input.is_action_pressed("move_left_enemy") or Input.is_action_pressed("move_right_enemy"):
		finished.emit(WALKING)
