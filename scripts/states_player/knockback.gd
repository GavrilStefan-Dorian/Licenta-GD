class_name Knockback
extends PlayerState

var knockback_duration := 0.8
var elapsed := 0.0

func enter(prev_state_path: String, data := {}) -> void:
	#player.animation_player.play("hit")
	player.velocity = data.get("knockback_velocity", Vector2.ZERO)
	elapsed = 0.0

func physics_update(delta: float) -> void:
	elapsed += delta
	player.velocity += player.get_gravity() * delta
	player.move_and_slide()

	if elapsed >= knockback_duration:
		#if not player.is_on_floor():
			#finished.emit(AIR) # causes issues by performing a jump
		#else:
			finished.emit(IDLE)
