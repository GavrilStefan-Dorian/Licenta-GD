class_name Enemy
extends CharacterBody2D

const SPEED = 400.0
const JUMP_VELOCITY = -550.0
const DASH_SPEED = 600.0
const DASH_DURATION = 0.3

var current_attack_damage: int = 0
var current_attack_knockback: Vector2 = Vector2.ZERO
var current_guard_break: bool = false
var current_hitstun_duration: float = 0.3
var attack_timer: float = 0
var can_attack: bool = true

var is_guarding: bool = false
var guard_damage_reduction: float = 1.0
var being_hit: bool = false
var is_invincible: bool = false

var can_dash: bool = true
var is_crouching: bool = false
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
    
    if hitbox_config.get("guard_break", false) and target.get("is_guarding", false):
        if target.has_method("force_state_transition"):
            target.force_state_transition("hitstun", {"hitstun_duration": hitbox_config.get("hitstun_duration", 0.3)})
    
    if hitbox_config.damage > 0 and target.has_method("take_damage"):
        target.take_damage(hitbox_config.damage)
    
    if hitbox_config.immediate_knockback != Vector2.ZERO and target.has_method("apply_knockback"):
        var knockback = hitbox_config.immediate_knockback
        knockback.x *= facing_direction
        target.apply_knockback(knockback)
    
    if not target.get("is_guarding", false) and target.has_method("apply_hitstun"):
        target.apply_hitstun(hitbox_config.get("hitstun_duration", 0.3))
    
    if hitbox_config.special_behavior:
        hitbox_config.special_behavior.call(target)
        
func take_damage(amount: int) -> void:
    if is_guarding:
        amount = int(amount * guard_damage_reduction)
        if amount <= 0:
            return
    
    if is_invincible:
        return
        
    Globals.enemy_health -= amount
    if Globals.enemy_health <= 0:
        Globals.player_wins += 1
        if Globals.player_wins >= ceil(Globals.MAX_ROUNDS / 2.0):  
            Globals.emit_signal("match_ended", "player")  
        else:
            Globals.emit_signal("round_ended", "player")  
        queue_free()
            
func apply_knockback(knockback_force: Vector2) -> void:
    if is_guarding:
        knockback_force *= 0.3
    
    if is_invincible:
        return
        
    var controller = get_node("StateMachineController")
    if controller:
        controller.state_machine.transition_to("knockback", {
            "knockback_velocity": knockback_force
        })
    else:
        velocity = knockback_force  # Fallback

func force_state_transition(new_state: String, data: Dictionary = {}) -> void:
    var controller = get_node("StateMachineController")
    if controller:
        controller.state_machine.transition_to(new_state, data)
        
func apply_hitstun(duration: float) -> void:
    force_state_transition("hitstun", {"hitstun_duration": duration})

func apply_status_effect(effect_name: String, duration: float) -> void:
    # Optional: implement status effects like burn, freeze
    pass