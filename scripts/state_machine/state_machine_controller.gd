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

func _process(delta: float) -> void:
	if state_machine:
		state_machine.update(delta)

func _physics_process(delta: float) -> void:
	if state_machine:
		state_machine.physics_update(delta)

func _unhandled_input(event: InputEvent) -> void:
	if state_machine:
		state_machine.handle_input(event)