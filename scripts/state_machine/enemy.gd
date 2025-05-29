class_name Enemy
extends CharacterBody2D

const SPEED = 400.0
const JUMP_VELOCITY = -550.0
const DASH_SPEED = 600.0
const DASH_DURATION = 0.3
var current_attack_damage: int = 0
var current_attack_knockback: Vector2 = Vector2.ZERO
var current_enemy_lift: float = 0
var attack_timer: float = 0
var can_attack: bool = true
var is_guarding: bool = false
var is_invincible: bool = false
var can_dash: bool = true
var facing_direction := -1  # 1 = right, -1 = left

var hitbox_config := {
	"is_active": false,
	"is_grapple": false,
	"damage": 0,
	"immediate_knockback": Vector2.ZERO,
	"special_behavior": null  # Callable for custom behaviors
}


@onready var animation_player = $AnimationPlayer
@onready var animated_sprite = $AnimatedSprite2D
@onready var hitbox = $HitBox

func _ready():
	add_to_group("enemies")
	
	if animation_player and animation_player.animation_finished.is_connected(_on_anim_finished):
		animation_player.animation_finished.disconnect(_on_anim_finished)
	if animation_player:
		animation_player.animation_finished.connect(_on_anim_finished)
	if hitbox:
		hitbox.area_entered.connect(_on_Hitbox_area_entered)

func _on_anim_finished(_anim_name: String):
	pass

func _on_Hitbox_area_entered(area: Area2D):
	if !area.is_in_group("hurtboxes") or !hitbox_config.is_active:
		return
		
	var hurtbox = area
	var target = hurtbox.owner
	
	if !target or !is_instance_valid(target):
		return
	
	if hitbox_config.damage > 0 and target.has_method("take_damage"):
		target.take_damage(hitbox_config.damage)
	
	if hitbox_config.immediate_knockback != Vector2.ZERO and target.has_method("apply_knockback"):
		var knockback = hitbox_config.immediate_knockback
		knockback.x *= facing_direction
		target.apply_knockback(knockback)
	
	# For grapple ( and maybe special debuffs )
	if hitbox_config.special_behavior:
		hitbox_config.special_behavior.call(target)
		
func take_damage(amount: int) -> void:
	if is_invincible or is_guarding:
		return
	Globals.enemy_health -= amount
	if Globals.enemy_health <= 0:
		Globals.player_wins += 1
		if Globals.player_wins >= ceil(Globals.MAX_ROUNDS / 2.0):  # Check PLAYER wins
			Globals.emit_signal("match_ended", "player")  # Player wins match
		else:
			Globals.emit_signal("round_ended", "player")  # Player wins round
		queue_free()
			
func apply_knockback(knockback_force: Vector2) -> void:
	if is_invincible or is_guarding:
		return
	var controller = get_node("StateMachineController")
	if controller:
		controller.state_machine.transition_to("knockback", {
			"knockback_velocity": knockback_force
		})
	else:
		velocity = knockback_force  # Fallback
