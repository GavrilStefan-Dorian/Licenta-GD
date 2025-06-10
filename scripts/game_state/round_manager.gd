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

    # Connect to health change signals to detect when characters are about to die
    Globals.stat_change_player.connect(_on_player_stat_change)
    Globals.stat_change_enemy.connect(_on_enemy_stat_change)

    # match_ui.set_pause_enabled(false)
    await get_tree().create_timer(0.5).timeout
    match_ui.show_match_start()
    await get_tree().create_timer(3.0).timeout
    match_ui.show_round_start(Globals.current_round)

func _on_round_start():
    # Resume AI at the start of a round
    resume_ai_if_needed()

func _on_round_ended(winner):
    # Pause AI when round ends
    pause_ai_if_needed()
    
    print("Round %d won by %s" % [Globals.current_round, winner])
    match_ui.show_round_end(winner, Globals.current_round)

    Globals.current_round += 1
    show_message("Round %d: %s wins!" % [Globals.current_round-1, winner])
    round_end_timer.start(2.0) 
    save_ai_model()

func _on_match_ended(winner):
    # Pause AI when match ends
    pause_ai_if_needed()
    print("Match won by %s!" % winner)
    show_message("Match Winner: %s!" % winner)
    match_ui.show_match_end(winner)
    match_end_timer.start(4.0)
    save_ai_model()

    # Save AI model if using DQN
    var enemies = get_tree().get_nodes_in_group("enemies")
    for enemy in enemies:
        if enemy.has_node("StateMachineController"):
            var smc = enemy.get_node("StateMachineController")
            if smc.state_machine and smc.state_machine.input_provider is DeepQLearningInputProvider:
                (smc.state_machine.input_provider as DeepQLearningInputProvider).save_model()

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

func save_ai_model():
    # Create a new HTTP request for saving the model
    var save_request = HTTPRequest.new()
    add_child(save_request)
    save_request.request_completed.connect(func(result, code, headers, body): 
        var json = JSON.new()
        var parse_result = json.parse(body.get_string_from_utf8())
        if parse_result == OK and json.get_data().has("message"):
            print("AI Model: " + json.get_data()["message"])
        save_request.queue_free()
    )

    # Prepare the save request
    var save_data = {
        "filepath": "E:/Licenta/Project/_game_prototype/dqn_script/models/fighting_ai_model_round.pkl"
    }

    var json_string = JSON.stringify(save_data)
    var headers = ["Content-Type: application/json"]
    save_request.request("http://localhost:5000/save_model", headers, HTTPClient.METHOD_POST, json_string)

# New function to detect player health changes
func _on_player_stat_change():
    if Globals.player_health <= 0:
        # Player is about to die, pause AI immediately
        pause_ai_if_needed()

# New function to detect enemy health changes
func _on_enemy_stat_change():
    if Globals.enemy_health <= 0:
        # Enemy is about to die, pause AI immediately
        pause_ai_if_needed()

# New helper function to pause all DQN AIs
func pause_ai_if_needed():
    var enemies = get_tree().get_nodes_in_group("enemies")
    for enemy in enemies:
        if enemy.has_node("StateMachineController"):
            var smc = enemy.get_node("StateMachineController")
            if smc.state_machine and smc.state_machine.input_provider is DeepQLearningInputProvider:
                (smc.state_machine.input_provider as DeepQLearningInputProvider).pause_ai()

# New helper function to resume all DQN AIs
func resume_ai_if_needed():
    var enemies = get_tree().get_nodes_in_group("enemies")
    for enemy in enemies:
        if enemy.has_node("StateMachineController"):
            var smc = enemy.get_node("StateMachineController")
            if smc.state_machine and smc.state_machine.input_provider is DeepQLearningInputProvider:
                (smc.state_machine.input_provider as DeepQLearningInputProvider).resume_ai()