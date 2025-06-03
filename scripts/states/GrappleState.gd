class_name GrappleState
extends State

const GRAPPLE_PULL_FORCE: Vector2 = Vector2(-200, -50) 
const GRAPPLE_PUSH_FORCE: Vector2 = Vector2(300, -100) 
const GRAPPLE_HITSTUN: float = 0.5
const GRAPPLE_HITSTUN_ON_GUARD_BREAK: float = 0.8 
const GRAPPLE_RECOVERY: float = 0.7 

var attack_timer: float = 0.0 

func grapple_behavior(character: CharacterBody2D) -> Callable:
	return func(target):
		var target_controller = target.get_node("StateMachineController")
		if target_controller:
			var pull_force = GRAPPLE_PULL_FORCE * character.facing_direction
			var push_force = GRAPPLE_PUSH_FORCE * character.facing_direction

			if target.is_guarding:
				target_controller.state_machine.transition_to("hurt", {
					"damage": 0,
					"knockback": pull_force,
					"hitstun_duration": GRAPPLE_HITSTUN_ON_GUARD_BREAK,
					"is_guard_broken_by_grapple": true
				})
				await character.get_tree().create_timer(0.2).timeout
				if is_instance_valid(target) and is_instance_valid(target_controller):
					target_controller.state_machine.transition_to("hurt", { 
						"damage": 0,
						"knockback": push_force,
						"hitstun_duration": GRAPPLE_HITSTUN_ON_GUARD_BREAK, 
						"is_guard_broken_by_grapple": true 
					})
			else:
				target_controller.state_machine.transition_to("hurt", {
					"damage": 0,
					"knockback": pull_force,
					"hitstun_duration": GRAPPLE_HITSTUN
				})
				await character.get_tree().create_timer(0.2).timeout
				if is_instance_valid(target) and is_instance_valid(target_controller):
					target_controller.state_machine.transition_to("hurt", {
						"damage": 0,
						"knockback": push_force,
						"hitstun_duration": GRAPPLE_HITSTUN
					})

func enter(_previous_state: String, _data: Dictionary = {}) -> void:
	var character = get_character()
	character.can_attack = false
	character.animation_player.play("primary_attack")
	attack_timer = 0.5 

	character.current_attack_damage = 0
	character.current_attack_knockback = Vector2.ZERO 
	character.current_hitstun_for_attack = GRAPPLE_HITSTUN 
	character.current_guard_break_for_attack = true
	character.attack_recovery_timer = GRAPPLE_RECOVERY
	
	if HitBoxConfigurator:
		character.hitbox_config = HitBoxConfigurator.configure_hitbox(character, Vector2(70,50), Vector2.ZERO, grapple_behavior, true)

func physics_update(delta: float) -> void:
	var character = get_character()
	var input = get_input()
	
	var input_direction_x = input.get_movement_axis()

	character.velocity.x = move_toward(character.velocity.x, 0, character.SPEED * 0.5) 
	character.velocity += character.get_gravity() * delta
	character.move_and_slide()
	
	attack_timer -= delta
	if character.attack_recovery_timer > 0:
		character.attack_recovery_timer -= delta
		return

	if attack_timer > 0: 
		return

	if input.is_action_pressed("jab"):
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

func exit() -> void:
	var character = get_character()
	character.can_attack = true
	if HitBoxConfigurator:
		character.hitbox_config = HitBoxConfigurator.reset()
