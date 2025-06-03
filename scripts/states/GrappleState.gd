class_name GrappleState
extends State

const grapple_pull_force: Vector2 = Vector2(-200, -50)
const grapple_push_force: Vector2 = Vector2(300, -100)
var attack_timer: float = 0.0

func grapple_behavior(character: CharacterBody2D) -> Callable:
	return func(target):
		if target.has_method("apply_knockback"):
			if target.has_method("force_state_transition"):
				target.force_state_transition("hitstun")
			# Pull phase
			var pull = grapple_pull_force
			pull.x *= character.facing_direction
			target.apply_knockback(pull)
			
			# Push phase after delay
			await character.get_tree().create_timer(0.2).timeout
			if is_instance_valid(target):
				var push = grapple_push_force
				push.x *= character.facing_direction
				target.apply_knockback(push)
				if target.has_method("apply_hitstun"):
					target.apply_hitstun(1.2)

func enter(_previous_state: String, _data: Dictionary = {}) -> void:
	var character = get_character()
	character.can_attack = false
	character.animation_player.play("primary_attack")
	attack_timer = 0.5
	
	character.current_guard_break = true
	character.current_hitstun_duration = 1.2
	if HitBoxConfigurator:
		character.hitbox_config = HitBoxConfigurator.configure_hitbox(character, Vector2(100,50), grapple_behavior)

func physics_update(delta: float) -> void:
	var character = get_character()
	var input = get_input()
	
	var input_direction_x = input.get_movement_axis()

	character.velocity.x = move_toward(character.velocity.x, 0, character.SPEED * 3)
	character.velocity += character.get_gravity() * delta
	character.move_and_slide()
	
	attack_timer -= delta
	if attack_timer > 0:
		return
	
	if input.is_action_pressed("jump"):
		transition_to("air")
	elif input.is_action_pressed("jab"):
		transition_to("attack", { "attack_type": "jab" })
	elif input.is_action_pressed("heavy_blow"):
		transition_to("attack", { "attack_type": "heavy_blow" })
	elif input.is_action_pressed("upper_cut"):
		transition_to("attack", { "attack_type": "uppercut" })
	elif input.is_action_pressed("guard"):
		transition_to("guard")
	elif input.is_action_pressed("dash"):
		transition_to("dash")
	elif is_equal_approx(input_direction_x, 0.0):
		transition_to("idle")
	elif input.is_movement_pressed():
		transition_to("walking")

func exit():
	var character = get_character()
	character.can_attack = true
	if HitBoxConfigurator:
		character.hitbox_config = HitBoxConfigurator.reset()
