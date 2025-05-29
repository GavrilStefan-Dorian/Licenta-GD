class_name DashState
extends State

var dash_timer: float

func enter(_previous_state: String, _data: Dictionary = {}) -> void:
	var character = get_character()
	character.can_dash = false
	character.animation_player.play("guard") 
	dash_timer = character.DASH_DURATION
	
	character.velocity.x = character.DASH_SPEED * character.facing_direction
	
	character.get_tree().create_timer(1.0).timeout.connect(func(): character.can_dash = true)

func physics_update(delta: float) -> void:
	var character = get_character()
	var input = get_input()
	
	# Don't apply gravity during dash for more control
	character.move_and_slide()
	
	dash_timer -= delta
	
	if dash_timer > 0:
		return
		
	var input_direction_x = input.get_movement_axis()
	
	if input.is_action_pressed("jump"):
		transition_to("air")
	elif input.is_action_pressed("jab"):
		transition_to("attack", { "attack_type": "jab" })
	elif input.is_action_pressed("heavy_blow"):
		transition_to("attack", { "attack_type": "heavy_blow" })
	elif input.is_action_pressed("upper_cut"):
		transition_to("attack", { "attack_type": "uppercut" })
	elif input.is_action_pressed("grapple"):
		transition_to("grapple")
	elif input.is_action_pressed("guard"):
		transition_to("guard")
	elif input.is_action_pressed("dash"):
		transition_to("dash")
	elif is_equal_approx(input_direction_x, 0.0):
		transition_to("idle")
	elif input.is_movement_pressed():
		transition_to("walking")