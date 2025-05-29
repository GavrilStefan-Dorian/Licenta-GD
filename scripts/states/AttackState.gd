class_name AttackState
extends State

var attack_data: Dictionary
var attack_type: String
var attack_timer: float = 0.0

var ATTACK_PRESETS = {
	"jab": {
		"damage": 4,
		"knockback": Vector2(120, -30),
		"hitstun": 0.2,
		"guard_break": false,
		"hitbox_size": Vector2(60, 40),
		"hitbox_offset": Vector2(0, -10)
	},
	"heavy_blow": {
		"damage": 12,
		"knockback": Vector2(300, -80),
		"hitstun": 0.5,
		"guard_break": false,
		"hitbox_size": Vector2(80, 60),
		"hitbox_offset": Vector2(10, -5)
	},
	"uppercut": {
		"damage": 8,
		"knockback": Vector2(80, -400),
		"hitstun": 0.6,
		"guard_break": true,
		"hitbox_size": Vector2(50, 100),
		"hitbox_offset": Vector2(-10, -30)
	},
	"low_jab": {
		"damage": 3,
		"knockback": Vector2(100, 0),
		"hitstun": 0.15,
		"guard_break": false,
		"hitbox_size": Vector2(70, 30),
		"hitbox_offset": Vector2(0, 20)
	},
	"air_attack": {
		"damage": 6,
		"knockback": Vector2(150, -100),
		"hitstun": 0.3,
		"guard_break": false,
		"hitbox_size": Vector2(70, 50),
		"hitbox_offset": Vector2(0, 10)
	}
}

func enter(_previous_state: String, data: Dictionary = {}) -> void:
	var character = get_character()
	character.can_attack = false
	attack_type = data.get("attack_type", "jab")
	attack_data = ATTACK_PRESETS[attack_type]
	
	character.animation_player.play("primary_attack")
	attack_timer = character.animation_player.get_animation("primary_attack").length
	
	character.current_attack_damage = attack_data.damage
	character.current_attack_knockback = attack_data.knockback
	character.current_guard_break = attack_data.guard_break
	character.current_hitstun_duration = attack_data.hitstun
	
	if HitBoxConfigurator:
		character.hitbox_config = HitBoxConfigurator.configure_hitbox(
			character, 
			attack_data.hitbox_size
		)

func physics_update(delta: float) -> void:
	var character = get_character()
	var input = get_input()
	
	character.velocity.x = move_toward(character.velocity.x, 0, character.SPEED * 2)
	character.velocity += character.get_gravity() * delta
	character.move_and_slide()

	attack_timer -= delta
	if attack_timer <= 0:
		var input_direction_x = input.get_movement_axis()
		if is_equal_approx(input_direction_x, 0.0):
			transition_to("idle")
		else:
			transition_to("walking")
	
func exit():
	var character = get_character()
	character.can_attack = true
	if HitBoxConfigurator:
		character.hitbox_config = HitBoxConfigurator.reset()
