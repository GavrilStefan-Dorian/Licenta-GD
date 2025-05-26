class_name GuardEnemy
extends EnemyState

func enter(previous_state_path: String, data := {}) -> void:
	enemy.animation_player.play("guard")  # Or guard animation
	enemy.is_guarding = true
	enemy.is_invincible = true

func physics_update(delta: float) -> void:
	# Stop movement while guarding
	enemy.velocity.x = move_toward(enemy.velocity.x, 0, enemy.SPEED * 2)
	enemy.velocity += enemy.get_gravity() * delta
	enemy.move_and_slide()
	
	# Exit guard when button released or other inputs
	if Input.is_action_just_released("guard_enemy"):
		finished.emit(IDLE)
	elif Input.is_action_just_pressed("jump_enemy"):
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

func exit():
	enemy.is_guarding = false
	enemy.is_invincible = false
