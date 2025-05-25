class_name RoundManager
extends Node

@export var player_scene: PackedScene
@export var enemy_scene: PackedScene
@export var player_spawn: Marker2D  
@export var enemy_spawn: Marker2D

#@onready var match_ui: CanvasLayer = $MatchUI
@onready var round_end_timer = $RoundEndTimer
@onready var match_end_timer = $MatchEndTimer

func _ready():
	await get_tree().process_frame
	#match_ui.update_scores(0, 0)
	#match_ui.show_round_start(1)
	
	Globals.round_ended.connect(_on_round_ended)
	Globals.match_ended.connect(_on_match_ended)

func _on_round_ended(winner):
	#match_ui.update_scores(Globals.player_wins, Globals.enemy_wins)
	#match_ui.show_round_result(winner)
	print("Round %d won by %s" % [Globals.current_round, winner])
	Globals.current_round += 1
	show_message("Round %d: %s wins!" % [Globals.current_round-1, winner])
	round_end_timer.start(2.0) 
	get_tree().paused = true

func _on_match_ended(winner):
	#match_ui.show_round_start(Globals.current_round)
	print("Match won by %s!" % winner)
	show_message("Match Winner: %s!" % winner)
	match_end_timer.start(4.0)
	get_tree().paused = true

func _on_round_end_timer_timeout():
	get_tree().paused = false
	respawn_players()
	Globals.reset_round_state()

func _on_match_end_timer_timeout():
	get_tree().paused = false
	respawn_players()
	Globals.reset_match_state()

func respawn_players():
	print("Player spawn position: ", player_spawn.position)
	
	for node in get_tree().get_nodes_in_group("players"):
		node.queue_free()
	
	var player = player_scene.instantiate()
	var enemy = enemy_scene.instantiate()
	
	player.position = player_spawn.position
	enemy.position = enemy_spawn.position
	
	get_tree().current_scene.add_child(player)
	get_tree().current_scene.add_child(enemy)

func show_message(text):
	print(text)  
