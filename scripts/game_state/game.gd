extends Node2D
class_name Game
var player: Player
var enemy: Enemy

func _ready() -> void:
	player = $Player
	enemy = $Enemy
	if Globals:
		Globals.reset_game_state()


func _process(delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(enemy):
		return
	
	
	if enemy.global_position.x < player.global_position.x:
		player.facing_direction = -1
	else:
			player.facing_direction = 1

	if player.global_position.x < enemy.global_position.x:
		enemy.facing_direction = -1
	else:
		enemy.facing_direction = 1
	
	player.animated_sprite.flip_h = player.facing_direction < 0
	enemy.animated_sprite.flip_h = enemy.facing_direction < 0

func register_player(new_player: CharacterBody2D):
	player = new_player

# Call this when your enemy character is ready
func register_enemy(new_enemy: CharacterBody2D):
	enemy = new_enemy
