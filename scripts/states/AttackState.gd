class_name AttackState
extends State

var attack_data: Dictionary
var attack_type: String
var attack_timer: float = 0.0

var ATTACK_PRESETS = {
	"jab": {
		"damage": 5,
		"knockback": Vector2(150, -50), 
		"enemy_lift": 0
	},
	"heavy_blow": {
		"damage": 10,
		"knockback": Vector2(300, -100),
		"enemy_lift": 0
	},
	"uppercut": {
		"damage": 3,
		"knockback": Vector2(100, -300),
		"enemy_lift": 100  
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
	character.current_enemy_lift = attack_data.enemy_lift
	
	if HitBoxConfigurator:
		character.hitbox_config = HitBoxConfigurator.configure_hitbox(character, Vector2(50, 50))

func physics_update(delta: float) -> void:
	var character = get_character()
	var input = get_input()
	
	var input_direction_x = input.get_movement_axis()
	
	character.velocity += character.get_gravity() * delta
	character.move_and_slide()

	attack_timer -= delta
	if attack_timer > 0:
		return
		
	if input.is_action_pressed("jump"):
		transition_to("air")
	elif is_equal_approx(input_direction_x, 0.0):
		transition_to("idle")
	elif input.is_movement_pressed():
		transition_to("walking")
	
func exit():
	var character = get_character()
	character.can_attack = true
	if HitBoxConfigurator:
		character.hitbox_config = HitBoxConfigurator.reset()