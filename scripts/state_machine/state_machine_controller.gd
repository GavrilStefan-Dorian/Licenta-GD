class_name StateMachineController
extends Node

var state_machine: StateMachine
var character: CharacterBody2D

func _ready():
	character = get_parent()
	
	await character.ready
	
	var input_provider: InputProvider
	if character.name.to_lower().contains("player"):
		input_provider = PlayerInputProvider.new()
	else:
		var enemy_script = character as Enemy
		var player_char_node = Globals.player_node 

		if not is_instance_valid(player_char_node):
			printerr("StateMachineController: Player node not found for AI. Defaulting to simple_keys.")
			input_provider = EnemyInputProvider.new() 
		elif enemy_script:
			match enemy_script.ai_type.to_lower():
				"basic":
					var basic_ai_provider = BasicAIInputProvider.new()
					basic_ai_provider._initialize_ai(character, player_char_node)
					input_provider = basic_ai_provider
				_:
						input_provider = EnemyInputProvider.new()
		else:
			input_provider = EnemyInputProvider.new()
			
	state_machine = StateMachine.new(character, input_provider)
	
	setup_states()
	
	state_machine.transition_to("idle")

func setup_states():
	state_machine.add_state("idle", IdleState.new())
	state_machine.add_state("walking", WalkingState.new())
	state_machine.add_state("air", AirState.new())
	state_machine.add_state("attack", AttackState.new())
	state_machine.add_state("grapple", GrappleState.new())
	state_machine.add_state("guard", GuardState.new())
	state_machine.add_state("dash", DashState.new())
	# state_machine.add_state("knockback", KnockbackState.new())
	state_machine.add_state("hurt", HurtState.new())
	state_machine.add_state("dying", DyingState.new())
	state_machine.add_state("air_attack", AirAttackState.new())


func _process(delta: float) -> void:
	if state_machine:
		if state_machine.input_provider is BasicAIInputProvider: # Add this
			(state_machine.input_provider as BasicAIInputProvider).update_ai(delta)
		state_machine.update(delta)

func _physics_process(delta: float) -> void:
	if state_machine:
		state_machine.physics_update(delta)

func _unhandled_input(event: InputEvent) -> void:
	if state_machine:
		state_machine.handle_input(event)
