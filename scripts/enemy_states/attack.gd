class_name AttackEnemy
extends EnemyState

var attack_data: Dictionary
var attack_type: String

# duration is more damaging than useful, find other way of slowing down atks 
var ATTACK_PRESETS = {
	"jab": {
		"damage": 5,
		"knockback": Vector2(150, -50), 
		"duration": 0.5,
		"movement_factor": 0.3,
		"enemy_lift": 0
	},
	"heavy_blow": {
		"damage": 10,
		"knockback": Vector2(1000, -100),
		"duration": 0.5,
		"movement_factor": 0.1, 	
		"enemy_lift": 0
	},
	"uppercut": {
		"damage": 3,
		"knockback": Vector2(100, -300),
		"duration": 0.5,
		"movement_factor": 0.3,
		"enemy_lift": 100  
	}
}

func enter(previous_state_path: String, data := {}) -> void:
	enemy.can_attack = false
	attack_type = data.get("attack_type", "jab")
	attack_data = ATTACK_PRESETS[attack_type]
	
	enemy.animation_player.play("primary_attack")
	enemy.attack_timer = attack_data.duration
	enemy.current_attack_damage = attack_data.damage
	enemy.current_attack_knockback = attack_data.knockback
	enemy.current_enemy_lift = attack_data.enemy_lift
	
	print("The damage is" + str(enemy.current_attack_damage))
	

	# Momentum
	enemy.velocity.x = enemy.SPEED * attack_data.movement_factor * enemy.facing_direction



func physics_update(delta: float) -> void:
	var input_direction_x := Input.get_axis("move_left_enemy", "move_right_enemy")
	# Movement during attack
	enemy.velocity.x = move_toward(
		enemy.velocity.x,
		input_direction_x * enemy.SPEED * attack_data.movement_factor,
		enemy.SPEED * delta 
	)
	enemy.velocity += enemy.get_gravity() * delta
	enemy.move_and_slide()

	enemy.attack_timer -= delta
	if enemy.attack_timer > 0:
		return
		
	if Input.is_action_just_pressed("jump_enemy"):
		finished.emit(AIR)
	elif is_equal_approx(input_direction_x, 0.0):
		finished.emit(IDLE)
	elif Input.is_action_pressed("move_left_enemy") or Input.is_action_pressed("move_right_enemy"):
		finished.emit(WALKING)
	
			
func exit():
	enemy.can_attack = true
	enemy.current_attack_damage = 0
	enemy.current_attack_knockback = Vector2.ZERO
