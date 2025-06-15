class_name Enemy
extends CharacterBody2D

@export var ai_type: String = "basic" # Options: "simple_keys", "basic", "dqn"

const SPEED = 400.0
const JUMP_VELOCITY = -550.0
const DASH_SPEED = 600.0
const DASH_DURATION = 0.3
var current_attack_damage: int = 0
var current_attack_knockback: Vector2 = Vector2.ZERO
var current_enemy_lift: float = 0 # This might be part of knockback or a special effect
var current_hitstun_for_attack: float = 0.0
var current_guard_break_for_attack: bool = false
var attack_recovery_timer: float = 0.0

var attack_timer: float = 0 # Animation related timer
var can_attack: bool = true
var is_guarding: bool = false
var is_invincible: bool = false
var can_dash: bool = true
var facing_direction := -1  # 1 = right, -1 = left

const GUARD_STUN_DURATION: float = 0.5

var current_guard_break: bool = false
var current_hitstun_duration: float = 0.3 
var guard_damage_reduction: float = 1.0
var being_hit: bool = false
var is_crouching: bool = false

var hitbox_config := {
    "is_active": false,
    "is_grapple": false,
    "damage": 0,
    "knockback": Vector2.ZERO,
    "special_behavior": null,
    "hitstun_duration": 0.0,
    "guard_break": false
}

@onready var animation_player = $AnimationPlayer
@onready var animated_sprite = $AnimatedSprite2D
@onready var hitbox = $HitBox

func _ready():
    add_to_group("enemies")

    Globals.register_enemy(self)
    if animation_player and animation_player.animation_finished.is_connected(_on_anim_finished):
        animation_player.animation_finished.disconnect(_on_anim_finished)
    if animation_player:
        animation_player.animation_finished.connect(_on_anim_finished)

func _on_anim_finished(_anim_name: String):
    pass
