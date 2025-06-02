class_name MatchUI
extends CanvasLayer

@export var pause_during_displays: bool = true
@export var show_displays: bool = true  # New toggle for displays

@onready var animation_player = find_child("AnimationPlayer", true, false)
@onready var main_label = find_child("MainLabel", true, false)
@onready var sub_label = find_child("SubLabel", true, false)
@onready var score_label = find_child("ScoreLabel", true, false)

var is_showing := false
var pause_count := 0 

func _ready():
    visible = false
    animation_player.process_mode = Node.PROCESS_MODE_ALWAYS

func show_match_start():
    if not show_displays:
        return
    _show_status("FIGHT!", "Match begins - First to %d wins!" % ceil(Globals.MAX_ROUNDS / 2.0), "", 2.0)

func show_round_start(round_number: int):
    if not show_displays:
        return
    var score_text = "Player %d - %d Enemy" % [Globals.player_wins, Globals.enemy_wins]
    _show_status("ROUND %d" % round_number, "Ready?", score_text, 1.5)

func show_round_end(winner: String, round_number: int):
    if not show_displays:
        return
    var main_text = ""
    var sub_text = ""
    
    print("DEBUG: winner parameter = '", winner, "'")  # Debug print
    
    if winner == "player":
        main_text = "ROUND WON!"
        sub_text = "You defeated your opponent"
    else:
        main_text = "ROUND LOST!"
        sub_text = "Your opponent defeated you"
    
    var score_text = "Player %d - %d Enemy" % [Globals.player_wins, Globals.enemy_wins]
    _show_status(main_text, sub_text, score_text, 2.5)

func show_match_end(winner: String):
    if not show_displays:
        return
    var main_text = ""
    var sub_text = ""
    
    print("DEBUG: match winner parameter = '", winner, "'")  # Debug print
    
    if winner == "player":
        main_text = "VICTORY!"
        sub_text = "You won the match!"
    else:
        main_text = "DEFEAT!"
        sub_text = "You lost the match!"
    
    var score_text = "Final Score: Player %d - %d Enemy" % [Globals.player_wins, Globals.enemy_wins]
    _show_status(main_text, sub_text, score_text, 4.0)

func _show_status(main_text: String, sub_text: String, score_text: String, duration: float):
    if is_showing:
        return
        
    is_showing = true
    main_label.text = main_text
    sub_label.text = sub_text
    score_label.text = score_text
    
    visible = true
    
    # Only pause if the option is enabled
    if pause_during_displays and pause_count == 0:
        get_tree().paused = true
    
    if pause_during_displays:
        pause_count += 1
    
    animation_player.play("show")
    await animation_player.animation_finished
    
    var timer = Timer.new()
    timer.process_mode = Node.PROCESS_MODE_ALWAYS
    timer.one_shot = true
    timer.wait_time = duration
    add_child(timer)
    timer.start()
    await timer.timeout
    timer.queue_free()
    
    animation_player.play("hide")
    await animation_player.animation_finished
    
    visible = false
    
    # Only unpause if we were handling pausing
    if pause_during_displays:
        pause_count -= 1
        if pause_count <= 0:
            get_tree().paused = false
            pause_count = 0
    
    is_showing = false

# Method to toggle displays at runtime
func set_displays_enabled(enabled: bool):
    show_displays = enabled

# Method to toggle pause setting at runtime
func set_pause_enabled(enabled: bool):
    pause_during_displays = enabled
    
    # If we're currently showing something and disabling pause, unpause immediately
    if not enabled and get_tree().paused and pause_count > 0:
        get_tree().paused = false
        pause_count = 0