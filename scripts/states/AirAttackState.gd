class_name AirAttackState
extends State

var attack_data: Dictionary
var attack_type: String
var attack_timer: float = 0.0

var AIR_ATTACK_PRESETS = {
	"air_jab": {
		"damage": 5,
		"knockback": Vector2(150, -50),
		"hitstun": 0.25,
		"guard_break": false,
		"hitbox_size": Vector2(60, 40),
		"hitbox_offset": Vector2(0, 5)
	},
	"air_heavy": {
		"damage": 8,
		"knockback": Vector2(200, -100),
		"hitstun": 0.4,
		"guard_break": false,
		"hitbox_size": Vector2(70, 50),
		"hitbox_offset": Vector2(5, 10)
	},
	"air_uppercut": {
		"damage": 6,
		"knockback": Vector2(80, -250),
		"hitstun": 0.5,
		"guard_break": true,
		"hitbox_size": Vector2(50, 80),
		"hitbox_offset": Vector2(5, -20)
	}
}

func enter(_previous_state: String, data: Dictionary = {}) -> void:
	var character = get_character()
	character.can_attack = false
	attack_type = data.get("attack_type", "air_jab")
	attack_data = AIR_ATTACK_PRESETS[attack_type]
	
	character.animation_player.play("primary_attack")
	attack_timer = character.animation_player.get_animation("primary_attack").length
	
	character.current_attack_damage = attack_data.damage
	character.current_attack_knockback = attack_data.knockback
	character.current_guard_break = attack_data.guard_break
	character.current_hitstun_duration = attack_data.hitstun
	
	if HitBoxConfigurator:
		character.hitbox_config = HitBoxConfigurator.configure_hitbox(
			character, 
			attack_data.hitbox_size,
			attack_data.hitbox_offset
		)

func physics_update(delta: float) -> void:
	var character = get_character()
	
	character.velocity += character.get_gravity() * delta
	character.move_and_slide()
	
	attack_timer -= delta
	
	if character.is_on_floor():
		transition_to("idle")
	elif attack_timer <= 0:
		transition_to("air", {"air_source": "knockback"})

func exit():
	var character = get_character()
	character.can_attack = true
	if HitBoxConfigurator:
		character.hitbox_config = HitBoxConfigurator.reset()
