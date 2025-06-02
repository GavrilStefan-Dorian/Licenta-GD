class_name Player
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
var facing_direction := 1  # 1 = right, -1 = left

var hitbox_config := {
    "is_active": false,
    "is_grapple": false,
    "damage": 0,
    "knockback": Vector2.ZERO,
    "special_behavior": null  # Callable for custom behaviors
}

@onready var animation_player = $AnimationPlayer
@onready var animated_sprite = $AnimatedSprite2D
@onready var hitbox = $HitBox

func _ready():
    add_to_group("players")
    
    if animation_player and animation_player.animation_finished.is_connected(_on_anim_finished):
        animation_player.animation_finished.disconnect(_on_anim_finished)
    if animation_player:
        animation_player.animation_finished.connect(_on_anim_finished)

func _on_anim_finished(_anim_name: String):
    pass

