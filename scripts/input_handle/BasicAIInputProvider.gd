class_name BasicAIInputProvider
extends InputProvider

var enemy_node: CharacterBody2D
var player_node: CharacterBody2D

var attack_range: float = 500.0      
var sight_range: float = 600.0        
var move_speed_factor: float = 0.7    

var attack_cooldown: float = 1.5     
var current_attack_cooldown: float = 0.0

var _current_input_direction_x: float = 0.0
var _current_actions: Dictionary = {} # ex {"jab": true}

func _initialize_ai(char_node: CharacterBody2D, target_node: CharacterBody2D):
    enemy_node = char_node
    player_node = target_node
    current_attack_cooldown = randf_range(0, attack_cooldown * 0.5) 

func update_ai(delta: float):
    if not is_instance_valid(enemy_node) or not is_instance_valid(player_node):
        _current_input_direction_x = 0.0
        _current_actions.clear()
        return

    _current_actions.clear()
    _current_input_direction_x = 0.0

    if current_attack_cooldown > 0:
        current_attack_cooldown -= delta

    var distance_to_player = enemy_node.global_position.distance_to(player_node.global_position)
    var direction_to_player_x = 0
    if player_node.global_position.x < enemy_node.global_position.x:
        direction_to_player_x = -1 # Player is to the left
    elif player_node.global_position.x > enemy_node.global_position.x:
        direction_to_player_x = 1  # Player to the right


    if direction_to_player_x != 0:
        enemy_node.facing_direction = direction_to_player_x

    if distance_to_player > sight_range:
        _current_input_direction_x = 0.0
        return

    if distance_to_player <= attack_range:
        if current_attack_cooldown <= 0:
            _current_actions["fireball"] = true 
            current_attack_cooldown = attack_cooldown
        else:
            _current_input_direction_x = 0.0 
    else:
        _current_input_direction_x = direction_to_player_x * move_speed_factor


func get_movement_axis() -> float:
    return _current_input_direction_x

func is_action_pressed(action_name: String) -> bool:
    return _current_actions.has(action_name) and _current_actions[action_name]

func is_action_just_pressed(action_name: String) -> bool:
    return is_action_pressed(action_name)

func is_movement_pressed() -> bool:
    return !is_equal_approx(_current_input_direction_x, 0.0)

func is_action_released(_action_name: String) -> bool:
    return false 