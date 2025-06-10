class_name DeepQLearningInputProvider
extends InputProvider

# HTTP connection
var http_request: HTTPRequest
var ai_server_url = "http://localhost:5000"
var waiting_for_action = false

# Action management
var current_action = ""
var action_duration = 0.1  # Hold actions for 100ms
var action_timer = 0.0

# State tracking
var previous_state = {}
var stored_actions = {}
var time_since_last_action = 0

# Game state references
var character: CharacterBody2D
var opponent: CharacterBody2D
var stage_width = 1024  # Adjust to your stage width

# Add a paused state variable
var ai_paused: bool = false

func _init(char_node: CharacterBody2D, opponent_node: CharacterBody2D):
	character = char_node
	opponent = opponent_node
	
	# Set up HTTP connection
	http_request = HTTPRequest.new()
	character.add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)
	
	# Initialize AI server
	var init_data = {
		"state_size": 15,
		"action_size": 11,
		"model_path": "E:/Licenta/Project/_game_prototype/dqn_script/models/fighting_ai_model.pkl"
	}
	_send_request("/initialize", init_data)

func get_movement_axis() -> float:
	if current_action == "move_left":
		return -1.0
	elif current_action == "move_right":
		return 1.0
	return 0.0

func is_action_pressed(action: String) -> bool:
	match action:
		"jump":
			return current_action == "jump"
		"jab":
			return current_action == "jab"
		"heavy_blow":
			return current_action == "heavy_blow"
		"upper_cut":
			return current_action == "upper_cut"
		"fireball":
			return current_action == "fireball"
		"grapple":
			return current_action == "grapple"
		"guard":
			return current_action == "guard"
		"dash":
			return current_action == "dash"
		_:
			return false

func is_action_released(action: String) -> bool:
	# Most actions are single-press in this system
	return false

func is_movement_pressed() -> bool:
	return current_action == "move_left" or current_action == "move_right"

# Add this method to pause the AI
func pause_ai() -> void:
	ai_paused = true
	print("DQN AI paused - waiting for next round")

# Add this method to resume the AI
func resume_ai() -> void:
	ai_paused = false
	previous_state = {}  # Clear previous state to avoid comparing across rounds
	time_since_last_action = 0
	print("DQN AI resumed")

func update_ai(delta: float) -> void:
	if ai_paused:
		return  # Don't process anything when paused
		
	# Update action timer
	time_since_last_action += 1
	
	if action_timer > 0:
		action_timer -= delta
		if action_timer <= 0:
			current_action = "idle"  # Reset to idle after action duration
	
	# Request new action every few frames
	if time_since_last_action >= 15 and not waiting_for_action:  # Every 15 frames / quarter second
		request_ai_action()

# Add safety check to request_ai_action
func request_ai_action() -> void:
	if waiting_for_action or ai_paused:
		return
		
	# Safety check for valid instances
	if not is_instance_valid(character) or not is_instance_valid(opponent):
		print("Warning: Invalid character or opponent reference, pausing AI")
		pause_ai()
		return
		
	var game_state = get_current_game_state()
	
	# If we have a previous state, send training data
	if not previous_state.is_empty():
		send_training_data(previous_state, game_state)
	
	# Request new action
	waiting_for_action = true
	_send_request("/get_action", game_state)
	previous_state = game_state.duplicate(true)

func _send_request(endpoint: String, data: Dictionary) -> void:
	var json_string = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]
	http_request.request(ai_server_url + endpoint, headers, HTTPClient.METHOD_POST, json_string)

func get_current_game_state() -> Dictionary:
	if not is_instance_valid(character) or not is_instance_valid(opponent):
		return {}
	
	var distance = character.global_position.distance_to(opponent.global_position)
	var relative_position = 1 if opponent.global_position.x > character.global_position.x else -1
	
	var my_state_name = "unknown"
	if character.has_node("StateMachineController"):
		var smc = character.get_node("StateMachineController")
		if smc.state_machine and smc.state_machine.current_state:
			my_state_name = smc.state_machine.current_state.name
	
	var enemy_state_name = "unknown"
	if opponent.has_node("StateMachineController"):
		var smc = opponent.get_node("StateMachineController")
		if smc.state_machine and smc.state_machine.current_state:
			enemy_state_name = smc.state_machine.current_state.name
	
	return {
		"my_health": Globals.enemy_health if character.is_in_group("enemies") else Globals.player_health,
		"enemy_health": Globals.player_health if character.is_in_group("enemies") else Globals.enemy_health,
		"my_position_x": character.global_position.x,
		"my_position_y": character.global_position.y,
		"enemy_position_x": opponent.global_position.x,
		"enemy_position_y": opponent.global_position.y,
		"normalized_distance": distance / stage_width,
		"relative_position": relative_position,
		"my_on_ground": character.is_on_floor(),
		"enemy_on_ground": opponent.is_on_floor(),
		"my_is_attacking": my_state_name in ["attack", "air_attack", "grapple"],
		"enemy_is_attacking": enemy_state_name in ["attack", "air_attack", "grapple"],
		"my_is_guarding": character.is_guarding,
		"enemy_is_guarding": opponent.is_guarding,
		"my_is_vulnerable": !character.is_invincible,
		"enemy_is_vulnerable": !opponent.is_invincible,
		"my_state": my_state_name,
		"enemy_state": enemy_state_name,
		"time_since_last_action": time_since_last_action
	}

func send_training_data(old_state: Dictionary, new_state: Dictionary) -> void:
	var reward = calculate_reward(old_state, new_state)
	var done = new_state["my_health"] <= 0 or new_state["enemy_health"] <= 0
	
	var action_id = -1
	match current_action:
		"idle": action_id = 0
		"move_left": action_id = 1
		"move_right": action_id = 2
		"jump": action_id = 3
		"jab": action_id = 4
		"heavy_blow": action_id = 5
		"upper_cut": action_id = 6
		"fireball": action_id = 7
		"grapple": action_id = 8
		"guard": action_id = 9
		"dash": action_id = 10
	
	if action_id == -1:
		action_id = 0  # Default to idle
	
	var training_data = {
		"current_state": old_state,
		"action": action_id,
		"reward": reward,
		"next_state": new_state,
		"done": done
	}
	
	var train_request = HTTPRequest.new()
	character.add_child(train_request)
	train_request.request_completed.connect(_on_train_completed.bind(train_request))
	
	var json_string = JSON.stringify(training_data)
	var headers = ["Content-Type: application/json"]
	train_request.request(ai_server_url + "/train_step", headers, HTTPClient.METHOD_POST, json_string)

func calculate_reward(old_state: Dictionary, new_state: Dictionary) -> float:
	var reward = 0.0
	
	# Health rewards
	var my_health_change = new_state["my_health"] - old_state["my_health"]
	var enemy_health_change = old_state["enemy_health"] - new_state["enemy_health"]
	
	reward += my_health_change * 0.5  # Negative if health decreased
	reward += enemy_health_change * 1.0  # Dealing damage is important
	
	# Distance rewards
	if new_state["my_state"] in ["attack", "grapple"] and new_state["normalized_distance"] < 0.15:
		reward += 0.2  # Reward for attacking when close
	
	# State rewards
	if old_state["my_state"] != "hurt" and new_state["my_state"] == "hurt":
		reward -= 0.5  # Penalize getting hurt
		
	if old_state["enemy_state"] != "hurt" and new_state["enemy_state"] == "hurt":
		reward += 1.0  # Reward for hurting enemy
	
	# Guard rewards
	if new_state["my_is_guarding"] and old_state["enemy_state"] == "attack" and new_state["enemy_state"] == "attack":
		reward += 0.5  # Reward for blocking attacks
	
	# Corner rewards
	var stage_margin = stage_width * 0.2
	if new_state["enemy_position_x"] < stage_margin or new_state["enemy_position_x"] > stage_width - stage_margin:
		if new_state["my_position_x"] > stage_margin and new_state["my_position_x"] < stage_width - stage_margin:
			reward += 0.3  # Reward for cornering the opponent
	
	return reward

func _on_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	waiting_for_action = false
	
	if response_code != 200:
		print("AI server request failed: ", response_code)
		return
		
	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())
	
	if parse_result != OK:
		print("Failed to parse AI response")
		return
		
	var response = json.get_data()
	if response.has("action"):
		current_action = response["action"]
		action_timer = action_duration
		time_since_last_action = 0

func _on_train_completed(train_request: HTTPRequest, result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	train_request.queue_free()

# Call this when a round ends to save the model
func save_model():
	var save_request = HTTPRequest.new()
	character.add_child(save_request)
	save_request.request_completed.connect(func(result, code, headers, body): save_request.queue_free())
	
	var save_data = {
		"filepath": "E:/Licenta/Project/_game_prototype/dqn_script/models/fighting_ai_model.pkl"
	}
	
	var json_string = JSON.stringify(save_data)
	var headers = ["Content-Type: application/json"]
	save_request.request(ai_server_url + "/save_model", headers, HTTPClient.METHOD_POST, json_string)
