class_name DashingEnemy
extends EnemyState

var dash_timer: float

func enter(_previous_state_path: String, _data := {}) -> void:
	enemy.can_dash = false
	enemy.animation_player.play("guard") 
	dash_timer = enemy.DASH_DURATION
	
	# Set dash velocity
	enemy.velocity.x = enemy.DASH_SPEED * enemy.facing_direction
	
	# Reset dash cooldown after delay
	enemy.get_tree().create_timer(1.0).timeout.connect(func(): enemy.can_dash = true)

func physics_update(delta: float) -> void:
	# Don't apply gravity during dash for more control
	enemy.move_and_slide()
	
	dash_timer -= delta
	
	if dash_timer > 0:
		return
		
	var input_direction_x := Input.get_axis("move_left_enemy", "move_right_enemy")
	
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
	elif is_equal_approx(input_direction_x, 0.0):
		finished.emit(IDLE)
	elif Input.is_action_pressed("move_left_enemy") or Input.is_action_pressed("move_right_enemy"):
		finished.emit(WALKING)
		
			
func exit():
	pass
