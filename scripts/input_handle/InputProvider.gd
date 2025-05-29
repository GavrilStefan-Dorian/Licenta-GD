class_name InputProvider
extends RefCounted

func get_movement_axis() -> float:
	return 0.0

func is_action_pressed(_action: String) -> bool:
	return false

func is_movement_pressed() -> bool:
	return false