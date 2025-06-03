class_name BasicAIInputProvider
extends InputProvider

var enemy_node: CharacterBody2D
var player_node: CharacterBody2D

# AI Parameters
var attack_range: float = 100.0       # How close to be to attack
var sight_range: float = 600.0        # How far the AI "sees" the player
var move_speed_factor: float = 0.7    # How fast the AI moves (0.0 to 1.0 of its normal speed)

var attack_cooldown: float = 1.5      # Seconds between attacks
var current_attack_cooldown: float = 0.0

# Internal state for current inputs
var _current_input_direction_x: float = 0.0
var _current_actions: Dictionary = {} # e.g., {"jab": true}

func _initialize_ai(char_node: CharacterBody2D, target_node: CharacterBody2D):
    enemy_node = char_node
    player_node = target_node
    current_attack_cooldown = randf_range(0, attack_cooldown * 0.5) # Stagger initial attacks

func update_ai(delta: float):
    if not is_instance_valid(enemy_node) or not is_instance_valid(player_node):
        _current_input_direction_x = 0.0
        _current_actions.clear()
        return

    # Clear previous frame's actions
    _current_actions.clear()
    _current_input_direction_x = 0.0

    # Update cooldown
    if current_attack_cooldown > 0:
        current_attack_cooldown -= delta

    var distance_to_player = enemy_node.global_position.distance_to(player_node.global_position)
    var direction_to_player_x = 0
    if player_node.global_position.x < enemy_node.global_position.x:
        direction_to_player_x = -1 # Player is to the left
    elif player_node.global_position.x > enemy_node.global_position.x:
        direction_to_player_x = 1  # Player is to the right

    # --- Basic Decision Logic ---

    # 1. Face the player
    if direction_to_player_x != 0:
        enemy_node.facing_direction = direction_to_player_x

    # 2. Check if player is in sight
    if distance_to_player > sight_range:
        # Player out of sight, do nothing or patrol (for now, do nothing)
        _current_input_direction_x = 0.0
        return

    # 3. Attack if in range and cooldown ready
    if distance_to_player <= attack_range:
        if current_attack_cooldown <= 0:
            _current_actions["jab"] = true # Attempt a jab
            current_attack_cooldown = attack_cooldown
        else:
            # In attack range but cooldown active, maybe hold position or a slight back-off
            _current_input_direction_x = 0.0 
    else:
        # Player in sight but not in attack range, move towards player
        _current_input_direction_x = direction_to_player_x * move_speed_factor


# --- InputProvider Interface Implementation ---
func get_movement_axis() -> float:
    return _current_input_direction_x

func is_action_pressed(action_name: String) -> bool:
    return _current_actions.has(action_name) and _current_actions[action_name]

func is_action_just_pressed(action_name: String) -> bool:
    # For this simple AI, "just_pressed" is the same as "is_pressed"
    # The action is set for one frame by update_ai()
    return is_action_pressed(action_name)

func is_movement_pressed() -> bool:
    return !is_equal_approx(_current_input_direction_x, 0.0)

func is_action_released(_action_name: String) -> bool:
    return false # AI doesn't model releases this way