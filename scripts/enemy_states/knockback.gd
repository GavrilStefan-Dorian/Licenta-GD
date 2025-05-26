class_name KnockbackEnemy
extends EnemyState

var knockback_duration := 0.8
var elapsed := 0.0

func enter(prev_state_path: String, data := {}) -> void:
	#enemy.animation_player.play("hit")
	enemy.velocity = data.get("knockback_velocity", Vector2.ZERO)
	elapsed = 0.0

func physics_update(delta: float) -> void:
	elapsed += delta
	enemy.velocity += enemy.get_gravity() * delta
	enemy.move_and_slide()

	if elapsed >= knockback_duration:
		#if not enemy.is_on_floor():
			#finished.emit(AIR) # causes issues by performing a jump
		#else:
			finished.emit(IDLE)
