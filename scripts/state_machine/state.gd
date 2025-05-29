class_name State
extends RefCounted

var state_machine: StateMachine
var name: String

func enter(_previous_state: String, _data: Dictionary = {}) -> void:
	pass

func exit() -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass

func handle_input(_event: InputEvent) -> void:
	pass

# Helper funcs
func get_character() -> CharacterBody2D:
	return state_machine.character

func get_input() -> InputProvider:
	return state_machine.input_provider

func transition_to(state_name: String, data: Dictionary = {}) -> void:
	state_machine.transition_to(state_name, data)