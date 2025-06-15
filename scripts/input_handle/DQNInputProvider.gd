extends InputProvider
class_name DeepQLearningInputProvider

var http_request: HTTPRequest
var train_http_request: HTTPRequest
var waiting_for_train: bool = false

var ai_server_url = "https://mounted-az-villas-found.trycloudflare.com/"
var waiting_for_action = false
var connection_retry_count = 0
var max_retries = 5
var request_in_progress = false

var current_action: String = "idle"
var action_duration = 0.8
var action_timer = 0.0

var previous_state: Dictionary = {}
var time_since_last_action: float = 0.0

var character: CharacterBody2D
var opponent: CharacterBody2D

@export var stage_width: float = 1920.0
var ai_paused: bool = false
var ai_initialized = false

const ACTION_NAME_TO_ID = {
	"idle": 0, "move_left":1, "move_right":2, "jump":3,
	"jab":4, "heavy_blow":5, "upper_cut":6,
	"fireball":7, "grapple":8, "guard":9, "dash":10
}

var action_states := {
	"guard": false,
	"move_left": false,
	"move_right": false,
}

var prev_action_states := {
	"guard": false,
	"move_left": false,
	"move_right": false,
}

var previous_action: String = "idle"

# Improved queue system
var get_action_queue: Array = []
var train_queue: Array = []
var processing_get_action = false
var processing_train = false

var last_executed_action: String = "idle"

# Add connection state tracking
var connection_established = false
var last_successful_request_time = 0.0

# Add node validity tracking
var nodes_valid = true

func _init(char_node: CharacterBody2D, opponent_node: CharacterBody2D):
	character = char_node
	opponent = opponent_node

	# Setup main HTTP request
	http_request = HTTPRequest.new()
	character.add_child(http_request)
	http_request.request_completed.connect(_on_action_request_completed)
	http_request.timeout = 10.0  # Reduced timeout
	http_request.use_threads = false  # Disable threading to prevent freezing
	
	# Setup training HTTP request
	train_http_request = HTTPRequest.new()
	character.add_child(train_http_request)
	train_http_request.request_completed.connect(_on_train_request_completed)
	train_http_request.timeout = 10.0  # Reduced timeout
	train_http_request.use_threads = false  # Disable threading to prevent freezing
	
	# Start connection check
	check_server_status()

func _send_request_simple(request_node: HTTPRequest, endpoint: String, data: Dictionary) -> bool:
	# Check if nodes are still valid before making request
	if not _validate_nodes():
		return false
		
	# Check if request node is available
	if request_node.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return false
	
	var json_string = JSON.stringify(data)
	var headers = [
		"Content-Type: application/json",
		"User-Agent: Godot/4.0",
		"Accept: application/json"
	]
	
	var full_url = ai_server_url.rstrip("/") + "/" + endpoint.lstrip("/")
	
	var error = request_node.request(full_url, headers, HTTPClient.METHOD_POST, json_string)
	
	if error != OK:
		printerr("Failed to start HTTP request for %s. Error: %s" % [endpoint, error])
		return false
	
	return true

func _validate_nodes() -> bool:
	if not is_instance_valid(character) or not is_instance_valid(opponent):
		nodes_valid = false
		return false
	
	if not character.is_inside_tree() or not opponent.is_inside_tree():
		nodes_valid = false
		return false
		
	nodes_valid = true
	return true

func initialize_agent():
	if not _validate_nodes():
		return
		
	var init_data = {
		"state_size": get_current_game_state().size(),
		"action_size": ACTION_NAME_TO_ID.size()
	}
	
	if _send_request_simple(http_request, "/initialize", init_data):
		print("Initialization request sent")
	else:
		print("Failed to send initialization request")

func check_server_status():
	if not _validate_nodes():
		return
		
	var status_request_node = HTTPRequest.new()
	character.add_child(status_request_node)
	status_request_node.request_completed.connect(_on_status_check_completed.bind(status_request_node))
	status_request_node.timeout = 8.0
	status_request_node.use_threads = false
	
	var full_url = ai_server_url.rstrip("/") + "/status"
	print("Checking server status at: %s" % full_url)
	
	var error = status_request_node.request(full_url, [], HTTPClient.METHOD_GET)
	if error != OK:
		printerr("Failed to start status check request. Error: %s" % error)
		if is_instance_valid(status_request_node):
			status_request_node.queue_free()

func _on_status_check_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, request_node: HTTPRequest):
	if is_instance_valid(request_node):
		request_node.queue_free()

	print("Status check - Result: %s, Code: %s" % [result, response_code])
	
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		print("AI Server status OK. Initializing agent")
		connection_established = true
		last_successful_request_time = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
		initialize_agent()
	else:
		connection_established = false
		var error_msg = ""
		match result:
			HTTPRequest.RESULT_CANT_CONNECT:
				error_msg = "Can't connect to server"
			HTTPRequest.RESULT_TIMEOUT:
				error_msg = "Connection timeout"
			HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
				error_msg = "TLS handshake failed"
			HTTPRequest.RESULT_NO_RESPONSE:
				error_msg = "No response from server"
			HTTPRequest.RESULT_REQUEST_FAILED:
				error_msg = "Request failed"
			_:
				error_msg = "Unknown error"
		
		print("Status check failed: %s (Result: %s, Code: %s)" % [error_msg, result, response_code])
		
		# Simple retry without await to prevent freezing
		connection_retry_count += 1
		if connection_retry_count < max_retries:
			print("Will retry server status check (attempt %d/%d)" % [connection_retry_count, max_retries])
			# Use a timer instead of await
			if _validate_nodes():
				var retry_timer = character.get_tree().create_timer(2.0)
				retry_timer.timeout.connect(check_server_status)
		else:
			printerr("AI server connection failed after %d attempts" % max_retries)

func update_ai(delta: float):
	if ai_paused or not ai_initialized or not connection_established or not _validate_nodes():
		return

	if action_timer > 0:
		action_timer -= delta
		if action_timer <= 0:
			current_action = "idle"

	time_since_last_action += delta
	
	# Process queued requests
	_process_queued_requests()
	
	if time_since_last_action >= 0.8: 
		var current_game_state = get_current_game_state()
		
		# Handle training
		if not previous_state.is_empty() and not processing_train:
			var done = current_game_state.get("my_health", 0.0) <= 0 or current_game_state.get("enemy_health", 0.0) <= 0
			var action_id = ACTION_NAME_TO_ID.get(last_executed_action, 0)
			var train_data = {
				"current_state": previous_state,
				"action": action_id,
				"next_state": current_game_state,
				"done": done
			}
			
			if _send_request_simple(train_http_request, "/train_step", train_data):
				processing_train = true
			else:
				train_queue.append({ "endpoint": "/train_step", "data": train_data, "context": "train_step" })
		
		previous_state = current_game_state.duplicate(true)
		
		# Handle action requests
		if not processing_get_action:
			if _send_request_simple(http_request, "/get_action", current_game_state):
				processing_get_action = true
				time_since_last_action = 0.0
			else:
				get_action_queue.append({ "endpoint": "/get_action", "data": current_game_state, "context": "get_action" })

	# Update action states
	for action in action_states.keys():
		prev_action_states[action] = action_states[action]
		action_states[action] = (current_action == action)

	if previous_action != current_action:
		if previous_action in ["guard", "move_left", "move_right"] and current_action != previous_action:
			_on_continuous_action_released(previous_action)
		if current_action in ["guard", "move_left", "move_right"] and previous_action != current_action:
			_on_continuous_action_started(current_action)
	previous_action = current_action

func _process_queued_requests():
	if not _validate_nodes():
		return
		
	# Process get_action queue
	if not get_action_queue.is_empty() and not processing_get_action:
		var req_data = get_action_queue.pop_front()
		if _send_request_simple(http_request, req_data.endpoint, req_data.data):
			processing_get_action = true
	
	# Process train queue
	if not train_queue.is_empty() and not processing_train:
		var req_data = train_queue.pop_front()
		if _send_request_simple(train_http_request, req_data.endpoint, req_data.data):
			processing_train = true

func _on_continuous_action_started(action: String):
	print("%s started" % action)

func _on_continuous_action_released(action: String):
	print("%s released" % action)

func get_movement_axis() -> float:
	if current_action == "move_left":
		return -1.0
	elif current_action == "move_right":
		return 1.0
	return 0.0

func is_action_pressed(action: String) -> bool:
	# Always validate nodes before accessing character properties
	if not _validate_nodes():
		return false
		
	if action_states.has(action):
		return action_states[action]
	match action:
		"jump": return current_action == "jump"
		"jab": return current_action == "jab"
		"heavy_blow": return current_action == "heavy_blow"
		"upper_cut": return current_action == "upper_cut"
		"fireball": return current_action == "fireball"
		"grapple": return current_action == "grapple"
		"dash": return current_action == "dash"
		_: return false

func is_action_just_pressed(action: String) -> bool:
	if not _validate_nodes():
		return false
	return action_states.has(action) and action_states[action] and not prev_action_states[action]

func is_action_just_released(action: String) -> bool:
	if not _validate_nodes():
		return false
	return action_states.has(action) and not action_states[action] and prev_action_states[action]

func is_action_released(action: String) -> bool:
	if not _validate_nodes():
		return false
	if action == "guard":
		return action_states.has("guard") and not action_states["guard"] and prev_action_states["guard"]
	return false

func is_movement_pressed() -> bool:
	return current_action == "move_left" or current_action == "move_right"

func get_current_action() -> String:
	return current_action

func get_current_game_state() -> Dictionary:
	if not _validate_nodes():
		return {}

	var dist_x = abs(character.position.x - opponent.position.x)
	var norm_dist = 0.0
	if stage_width > 0:
		norm_dist = clamp(dist_x / stage_width, 0.0, 1.0)

	var my_current_health = 0.0
	var opponent_current_health = 0.0

	if character.is_in_group("enemies"):
		my_current_health = float(Globals.enemy_health)
	elif character.is_in_group("players"):
		my_current_health = float(Globals.player_health)

	if opponent.is_in_group("players"):
		opponent_current_health = float(Globals.player_health)
	elif opponent.is_in_group("enemies"):
		opponent_current_health = float(Globals.enemy_health)

	var my_is_vulnerable = not character.get("is_invincible") if "is_invincible" in character else true
	var enemy_is_vulnerable = not opponent.get("is_invincible") if "is_invincible" in opponent else true

	return {
		"my_health": my_current_health,
		"enemy_health": opponent_current_health,
		"my_position_x": float(character.position.x),
		"my_position_y": float(character.position.y),
		"enemy_position_x": float(opponent.position.x),
		"enemy_position_y": float(opponent.position.y),
		"normalized_distance": norm_dist,
		"relative_position": float(sign(opponent.position.x - character.position.x)),
		"my_on_ground": bool(character.is_on_floor()),
		"enemy_on_ground": bool(opponent.is_on_floor()),
		"my_is_attacking": bool(character.get("is_attacking") if "is_attacking" in character else false),
		"enemy_is_attacking": bool(opponent.get("is_attacking") if "is_attacking" in opponent else false),
		"my_is_guarding": bool(character.get("is_guarding") if "is_guarding" in character else false),
		"enemy_is_guarding": bool(opponent.get("is_guarding") if "is_guarding" in opponent else false),
		"my_is_vulnerable": my_is_vulnerable,
		"enemy_is_vulnerable": enemy_is_vulnerable,
		"time_since_last_action": float(time_since_last_action)
	}

func _on_action_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	processing_get_action = false
	
	# Check if we should still process this response
	if ai_paused or not _validate_nodes():
		print("Ignoring action response - AI paused or nodes invalid")
		return
	
	if result != HTTPRequest.RESULT_SUCCESS:
		print("Action request failed with result: %s" % result)
		if result == HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
			connection_established = false
		return
	
	var response_body_text = body.get_string_from_utf8().strip_edges()
	
	if response_body_text == "":
		printerr("Empty response body received in get_action")
		return
	
	var json_response = JSON.parse_string(response_body_text)
	if json_response == null:
		printerr("Failed to parse JSON response: %s" % response_body_text)
		return
	
	if response_code == 200 and typeof(json_response) == TYPE_DICTIONARY:
		var response_data: Dictionary = json_response
		if response_data.get("status") == "success":
			if response_data.has("action_name"):
				current_action = response_data["action_name"]
				last_executed_action = current_action
				action_timer = action_duration
				time_since_last_action = 0
				print("%s - Received action: %s" % [get_formatted_datetime(), current_action])
				last_successful_request_time = Time.get_time_dict_from_system().hour * 3600 + Time.get_time_dict_from_system().minute * 60 + Time.get_time_dict_from_system().second
			elif response_data.has("message") and response_data["message"] == "Agent initialized":
				print("%s - AI Agent initialized successfully" % get_formatted_datetime())
				ai_initialized = true
		else:
			printerr("Server returned error: %s" % response_data.get("message", "Unknown error"))
	else:
		printerr("Action request failed - Code: %s, Body: %s" % [response_code, response_body_text])

func _on_train_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	processing_train = false
	
	if result != HTTPRequest.RESULT_SUCCESS:
		print("Train request failed with result: %s" % result)
		return
	
	# Training requests don't need detailed response handling
	if response_code != 200:
		print("Train request failed with code: %s" % response_code)

func pause_ai():
	ai_paused = true
	print("AI Paused")
	# Clear all state
	get_action_queue.clear()
	train_queue.clear()
	processing_get_action = false
	processing_train = false
	current_action = "idle"
	action_timer = 0.0
	
	# Cancel any ongoing requests by setting a flag
	# The response handlers will check this flag

func resume_ai():
	ai_paused = false
	previous_state.clear()
	time_since_last_action = 0.25
	current_action = "idle"
	action_timer = 0.0
	processing_get_action = false
	processing_train = false
	print("AI Resumed")

func get_formatted_datetime() -> String:
	var dt = Time.get_time_dict_from_system()
	return "%02d:%02d:%02d" % [dt.hour, dt.minute, dt.second]
