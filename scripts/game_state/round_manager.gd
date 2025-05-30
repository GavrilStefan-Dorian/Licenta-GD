class_name RoundManager
extends Node

@export var player_scene: PackedScene
@export var enemy_scene: PackedScene
@export var player_spawn: Marker2D  
@export var enemy_spawn: Marker2D

@onready var match_ui: CanvasLayer = $MatchUI
@onready var round_end_timer = $RoundEndTimer
@onready var match_end_timer = $MatchEndTimer

func _ready():
	await get_tree().process_frame
	
	Globals.round_ended.connect(_on_round_ended)
	Globals.match_ended.connect(_on_match_ended)

	# match_ui.set_pause_enabled(false)
	await get_tree().create_timer(0.5).timeout
	match_ui.show_match_start()
	await get_tree().create_timer(3.0).timeout
	match_ui.show_round_start(Globals.current_round)

func _on_round_ended(winner):
	print("Round %d won by %s" % [Globals.current_round, winner])
	match_ui.show_round_end(winner, Globals.current_round)

	Globals.current_round += 1
	show_message("Round %d: %s wins!" % [Globals.current_round-1, winner])
	round_end_timer.start(2.0) 

func _on_match_ended(winner):
	print("Match won by %s!" % winner)
	show_message("Match Winner: %s!" % winner)
	match_ui.show_match_end(winner)
	match_end_timer.start(4.0)

func _on_round_end_timer_timeout():
	respawn_players()
	Globals.reset_round_state()
	await get_tree().create_timer(0.5).timeout

	if Globals.current_round <= Globals.MAX_ROUNDS:
		match_ui.show_round_start(Globals.current_round)

func _on_match_end_timer_timeout():
	respawn_players()
	Globals.reset_match_state()
	await get_tree().create_timer(1.0).timeout

	match_ui.show_match_start()
	await get_tree().create_timer(3.0).timeout
	match_ui.show_round_start(Globals.current_round)

func respawn_players():
	for node in get_tree().get_nodes_in_group("players"):
		node.queue_free()
	for node in get_tree().get_nodes_in_group("enemies"):
		node.queue_free()
	
	var player = await spawn_character(player_scene, player_spawn.global_position)
	var enemy = await spawn_character(enemy_scene, enemy_spawn.global_position)
	
	await get_tree().process_frame # wait for _readys()

func spawn_character(scene: PackedScene, position: Vector2) -> Node2D:
	await get_tree().process_frame # wait for queue_frees
	var inst = scene.instantiate()

	get_tree().current_scene.add_child(inst)
	await get_tree().process_frame # wait for _readys()

	inst.global_position = position
	return inst
	
func show_message(text):
	print(text)
