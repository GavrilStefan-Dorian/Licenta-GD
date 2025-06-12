extends InputProvider
class_name DeepQLearningInputProvider

var http_request: HTTPRequest
var train_http_request: HTTPRequest
var waiting_for_train: bool = false

var ai_server_url = "https://runner-compromise-sales-all.trycloudflare.com/"
var waiting_for_action = false
var connection_retry_count = 0
var max_retries = 3
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

var previous_action: String = "idle" #

var get_action_queue: Array = []
var train_queue: Array = []

var last_executed_action: String = "idle"

func _init(char_node: CharacterBody2D, opponent_node: CharacterBody2D):
	character = char_node
	opponent = opponent_node

	http_request = HTTPRequest.new()
	character.add_child(http_request)
	http_request.request_completed.connect(_on_action_request_completed)
	http_request.timeout = 5.0
	http_request.set_tls_options(TLSOptions.client())

	http_request.use_threads = true
	train_http_request = HTTPRequest.new()
	character.add_child(train_http_request)
	train_http_request.request_completed.connect(_on_train_request_completed)
	train_http_request.timeout = 5.0
	train_http_request.use_threads = true
	train_http_request.set_tls_options(TLSOptions.client())
	check_server_status()

func _send_generic_request(request_node: HTTPRequest, endpoint: String, data: Dictionary, context: String):
	if request_node.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		if context.find("get_action") != -1:
			get_action_queue.append({ "endpoint": endpoint, "data": data, "context": context })
		elif context.find("train_step") != -1:
			train_queue.append({ "endpoint": endpoint, "data": data, "context": context })
		else:
			printerr("No queue defined for context: %s" % context)
		return
	
	var json_string = JSON.stringify(data)
	var headers = [
		"Content-Type: application/json",
	]
	var error = request_node.request(ai_server_url + endpoint.lstrip("/"), headers, HTTPClient.METHOD_POST, json_string)
	if error != OK:
		printerr("Failed to start HTTP request for %s. Error: %s" % [context, error])

func initialize_agent():
	var init_data = {
		"state_size": get_current_game_state().size(),
		"action_size": ACTION_NAME_TO_ID.size()
	}
	_send_generic_request(http_request, "/initialize", init_data, "initialize")


func check_server_status():
	if not is_instance_valid(character): return
	var status_request_node = HTTPRequest.new() # temporary, for status check
	character.add_child(status_request_node)
	status_request_node.request_completed.connect(_on_status_check_completed.bind(status_request_node))
	status_request_node.set_tls_options(TLSOptions.client())
	status_request_node.request(ai_server_url + "status", [], HTTPClient.METHOD_GET)

func _on_status_check_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, request_node: HTTPRequest):
	if is_instance_valid(request_node):
		request_node.queue_free()

	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		print("AI Server status OK. Initializing agent")
		initialize_agent()
	else:
		printerr("Status check failed. Result: %s, Code: %s" % [result, response_code])
		connection_retry_count += 1
		if connection_retry_count < max_retries:
			print("Retrying server status check in 2 seconds")
			if is_instance_valid(character) and character.is_inside_tree():
				await character.get_tree().create_timer(2.0).timeout
				check_server_status()
			else:
				printerr("Character not in tree")
		else:
			printerr("AI server connection failed")

func update_ai(delta: float):
	if ai_paused or not ai_initialized:
		return

	if action_timer > 0:
		action_timer -= delta
		if action_timer <= 0:
			current_action = "idle"

	time_since_last_action += delta
	
	if time_since_last_action >= 0.8: 
		var current_game_state = get_current_game_state()
		
		if not previous_state.is_empty():
			if not waiting_for_train and train_http_request.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
				var done = current_game_state.get("my_health", 0.0) <= 0 or current_game_state.get("enemy_health", 0.0) <= 0
				var action_id = ACTION_NAME_TO_ID.get(last_executed_action, 0)  # Use last executed action
				var train_data = {
					"current_state": previous_state,
					"action": action_id,
					"next_state": current_game_state,
					"done": done
				}
				waiting_for_train = true
				_send_generic_request(train_http_request, "/train_step", train_data, "train_step")
			# else:
				# printerr("Train HTTPRequest busy, skipping train_step request.")
		
		previous_state = current_game_state.duplicate(true)
		
		if not waiting_for_action and http_request.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
			waiting_for_action = true
			_send_generic_request(http_request, "/get_action", current_game_state, "get_action")
			time_since_last_action = 0.0
		else:
			pass

	for action in action_states.keys():
		prev_action_states[action] = action_states[action]
		action_states[action] = (current_action == action)

	if previous_action != current_action:
		if previous_action in ["guard", "move_left", "move_right"] and current_action != previous_action:
			_on_continuous_action_released(previous_action)
		if current_action in ["guard", "move_left", "move_right"] and previous_action != current_action:
			_on_continuous_action_started(current_action)
	previous_action = current_action

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
	return action_states.has(action) and action_states[action] and not prev_action_states[action]

func is_action_just_released(action: String) -> bool:
	return action_states.has(action) and not action_states[action] and prev_action_states[action]

func is_action_released(action: String) -> bool:
	if action == "guard":
		return action_states.has("guard") and not action_states["guard"] and prev_action_states["guard"]
	return false

func is_movement_pressed() -> bool:
	return current_action == "move_left" or current_action == "move_right"

func get_current_action() -> String:
	return current_action

func get_current_game_state() -> Dictionary:
	if not is_instance_valid(character) or not is_instance_valid(opponent):
		printerr("Character or Opponent node invalid")
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

func _process_next_get_action_request():
	if get_action_queue.is_empty():
		return
	if http_request.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
		var req_data = get_action_queue.pop_front()
		_send_generic_request(http_request, req_data.endpoint, req_data.data, req_data.context)

func _process_next_train_request():
	if train_queue.is_empty():
		return
	if train_http_request.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
		var req_data = train_queue.pop_front()
		_send_generic_request(train_http_request, req_data.endpoint, req_data.data, req_data.context)


func _on_action_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	waiting_for_action = false
	
	if result != HTTPRequest.RESULT_SUCCESS:
		printerr("Action request failed with result: %s" % result)
		_process_next_get_action_request()
		return
	
	var response_body_text = body.get_string_from_utf8().strip_edges()
	var endpoint_context = "get_action"
	
	if response_body_text == "":
		printerr("Empty response body received in get_action. Context: %s" % endpoint_context)
		_process_next_get_action_request()
		return
	
	var json_response
	var parse_error = false
	
	json_response = JSON.parse_string(response_body_text)
	if json_response == null:
		printerr("Failed to parse JSON response for Action/Init. Body: <<< %s >>>. Context: %s" % [response_body_text, endpoint_context])
		_process_next_get_action_request()
		return
	
	if response_code == 200 and typeof(json_response) == TYPE_DICTIONARY:
		var response_data: Dictionary = json_response
		if response_data.get("status") == "success":
			if response_data.has("action_name"):
				current_action = response_data["action_name"]
				last_executed_action = current_action  # Store it immediately
				action_timer = action_duration
				time_since_last_action = 0
				print("%s - Received /get_action: %s" % [get_formatted_datetime(), response_body_text])
			elif response_data.has("message") and response_data["message"] == "Agent initialized":
				print("%s - AI Agent initialized successfully on server." % get_formatted_datetime())
				ai_initialized = true
		else:
			printerr("Action/Init server returned error: %s. Context: %s" % [response_data.get("message", "Unknown error"), endpoint_context])
	else:
		printerr("Action/Init request completed with code: %s. Body: %s. Context: %s" % [response_code, response_body_text, endpoint_context])
	
	_process_next_get_action_request()

func _on_train_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
	waiting_for_train = false
	if result != HTTPRequest.RESULT_SUCCESS:
		printerr("Train request failed or timed out. Result: %s" % result)
		_process_next_train_request()
		return
	
	var response_body_text = body.get_string_from_utf8()
	if response_body_text.is_empty() and response_code != 204:
		printerr("Received empty response body for Train request (Code: %s)." % response_code)
		_process_next_train_request()
		return
	
	_process_next_train_request()

func pause_ai():
	ai_paused = true
	print("AI Paused")
	get_action_queue.clear()
	train_queue.clear()
	waiting_for_action = false
	waiting_for_train = false

func resume_ai():
	ai_paused = false
	previous_state.clear()
	time_since_last_action = 0.25
	print("AI Resumed")

func get_formatted_datetime() -> String:
	var dt = Time.get_time_dict_from_system()
	return "%02d:%02d:%02d" % [dt.hour, dt.minute, dt.second]
