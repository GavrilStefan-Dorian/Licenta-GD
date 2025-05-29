extends Node

signal stat_change_player

var player_vulnerable: bool = true
var player_health = 100:
	set(value):
		if player_vulnerable:
			player_health = value
			player_vulnerable = false
			player_invulnerable_timer()
		stat_change_player.emit()

func player_invulnerable_timer():
	await get_tree().create_timer(0.2).timeout
	player_vulnerable = true

var player_pos: Vector2

signal stat_change_enemy
var enemy_vulnerable: bool = true
var enemy_health = 100:
	set(value):
		if enemy_vulnerable:
			enemy_health = value
			enemy_vulnerable = false
			enemy_invulnerable_timer()
		stat_change_enemy.emit()

func enemy_invulnerable_timer():
	await get_tree().create_timer(0.2).timeout
	enemy_vulnerable = true

var enemy_pos: Vector2

func reset_game_state():
	player_health = 100
	enemy_health = 100
	player_vulnerable = true
	enemy_vulnerable = true
	
var player_wins := 0
var enemy_wins := 0
var current_round := 1
const MAX_ROUNDS := 3

signal round_ended(winner)  # "player" or "enemy"
signal match_ended(winner)  # "player" or "enemy"

func reset_round_state():
	player_health = 100
	enemy_health = 100
	player_vulnerable = true
	enemy_vulnerable = true

func reset_match_state():
	player_wins = 0
	enemy_wins = 0
	current_round = 1
	reset_round_state()
