class_name StateMachine
extends RefCounted

signal state_changed(from_state: String, to_state: String, data: Dictionary)

var current_state: State
var states: Dictionary = {}
var character: CharacterBody2D
var input_provider: InputProvider

func _init(chr: CharacterBody2D, input_prov: InputProvider):
	character = chr
	input_provider = input_prov

func add_state(name: String, state: State) -> void:
	states[name] = state
	state.state_machine = self
	state.name = name

func transition_to(state_name: String, data: Dictionary = {}) -> void:
	# print(str(character) + state_name)
	if not states.has(state_name):
		push_error("State " + state_name + " does not exist")
		return
	
	var previous_state_name = current_state.name if current_state else ""
	
	if current_state:
		current_state.exit()
	
	current_state = states[state_name]
	current_state.enter(previous_state_name, data)
	
	state_changed.emit(previous_state_name, state_name, data)

func update(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func physics_update(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func handle_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)
