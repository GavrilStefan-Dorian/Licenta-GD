class_name EnemyInputProvider
extends InputProvider

func get_movement_axis() -> float:
	return Input.get_axis("move_left_enemy", "move_right_enemy")

func is_action_pressed(action: String) -> bool:
	match action:
		"jump":
			return Input.is_action_just_pressed("jump_enemy")
		"jab":
			return Input.is_action_just_pressed("jab_enemy")
		"heavy_blow":
			return Input.is_action_just_pressed("heavy_blow_enemy")
		"upper_cut":
			return Input.is_action_just_pressed("upper_cut_enemy")
		"fireball":
			return Input.is_action_just_pressed("fireball_enemy")
		"grapple":
			return Input.is_action_just_pressed("grapple_enemy")
		"guard":
			return Input.is_action_just_pressed("guard_enemy")
		"dash":
			return Input.is_action_just_pressed("dash_enemy")
		_:
			return false

func is_movement_pressed() -> bool:
	return Input.is_action_pressed("move_left_enemy") or Input.is_action_pressed("move_right_enemy")

func is_action_released(action: String) -> bool:
	match action:
		"guard":
			return Input.is_action_just_released("guard_enemy")
		_:
			return false