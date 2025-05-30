class_name PlayerInputProvider
extends InputProvider

var input_blocked := false

func get_movement_axis() -> float:
	return Input.get_axis("move_left", "move_right")

func is_action_pressed(action: String) -> bool:

	match action:
		"jump":
			return Input.is_action_just_pressed("jump")
		"jab":
			return Input.is_action_just_pressed("jab")
		"heavy_blow":
			return Input.is_action_just_pressed("heavy_blow")
		"upper_cut":
			return Input.is_action_just_pressed("upper_cut")
		"grapple":
			return Input.is_action_just_pressed("grapple")
		"guard":
			return Input.is_action_just_pressed("guard")
		"dash":
			return Input.is_action_just_pressed("dash")
		_:
			return false

func is_movement_pressed() -> bool:
	return (Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"))

func is_action_released(action: String) -> bool:
	match action:
		"guard":
			return Input.is_action_just_released("guard")
		_:
			return false