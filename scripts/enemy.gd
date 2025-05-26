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

@onready var animation_player = $AnimationPlayer
@onready var animated_sprite = $AnimatedSprite2D
@onready var hitbox = $HitBox
@onready var camera = $"../Background/Camera2D"
#@onready var hit_spark = $HitSpark

func _ready():
	add_to_group("enemies")
	
	if animation_player and animation_player.animation_finished.is_connected(_on_anim_finished):
		animation_player.animation_finished.disconnect(_on_anim_finished)
	if animation_player:
		animation_player.animation_finished.connect(_on_anim_finished)
	if hitbox:
		hitbox.area_entered.connect(_on_Hitbox_area_entered)
			#hitbox.area_entered.connect(_on_Hitbox_area_entered)

func _on_anim_finished(anim_name: String):
	# Handle animation completions if needed
	pass
#
func _on_Hitbox_area_entered(area: Area2D):
	if area == null:
		return
	if not area.is_in_group("hurtboxes"):
		return
	var hurtbox = area
	var enemy = hurtbox.owner
	if enemy and enemy.has_method("take_damage") and attack_timer > 0 and current_attack_damage > 0:
		enemy.take_damage(current_attack_damage)
		enemy.apply_knockback(current_attack_knockback * facing_direction)
		# Prevent multi-hit per swing
		current_attack_damage = 0

	
func take_damage(amount: int) -> void:
	print(amount)
	Globals.enemy_health -= amount
	if Globals.enemy_health <= 0:
		Globals.player_wins += 1
		if Globals.player_wins >= ceil(Globals.MAX_ROUNDS / 2.0):
			Globals.emit_signal("match_ended", "player")
		else:
			Globals.emit_signal("round_ended", "player")
		queue_free()
			
func apply_knockback(knockback_force: Vector2) -> void:
	velocity.x = knockback_force.x
	velocity.y = knockback_force.y
	
#func apply_force(force:Vector2, lift: float = 0) -> void:
	#velocity.x = force.x
	#velocity.y = force.y
	#if lift > 0: 
		#velocity.y = -lift

#class_name Enemy
#extends CharacterBody2D
#
#const SPEED = 400.0
#const JUMP_VELOCITY = -350.0
#
#enum PlayerState { IDLE, WALKING, ATTACKING }
#var current_state := PlayerState.IDLE
#var can_attack := true
#var facing_direction := 1  # 1 = right, -1 = left
#
#
#@onready var anim_player = $AnimationPlayer
#@onready var animated_sprite = $AnimatedSprite2D 
#
#func _ready():
	#add_to_group("players")
	#add_to_group("enemies")
	#if anim_player.animation_finished.is_connected(_on_anim_finished): 
			#anim_player.animation_finished.disconnect(_on_anim_finished) 
	#anim_player.animation_finished.connect(_on_anim_finished)
	#
#func handleInput():
	#var direction := Input.get_axis("ui_left", "ui_right")
	#if direction:
		#velocity.x = direction * SPEED
		##animated_sprite.flip_h = direction < 0 	
	#else:
		#velocity.x = move_toward(velocity.x, 0, SPEED)
#
#func updateAnimation():
	#if current_state == PlayerState.ATTACKING:
		#return
		#
	#if is_zero_approx(velocity.length()):
		#if anim_player.current_animation != "idle":
			#anim_player.play("idle")
		#current_state = PlayerState.IDLE
	#else:
		#if  not is_zero_approx(velocity.x) and anim_player.current_animation != "walking":
			#anim_player.play("walking")
			#current_state = PlayerState.WALKING
		#
#func _physics_process(delta: float) -> void:
	#if not is_on_floor():
		#velocity += get_gravity() * delta
#
	##if Input.is_action_just_pressed("ui_accept") and is_on_floor() and current_state != PlayerState.ATTACKING:
		##velocity.y = JUMP_VELOCITY
		#
	#if Input.is_action_just_pressed("secondary_action") and can_attack:
		#start_attack()
#
	#handleInput()
	#move_and_slide()
	#
	#if current_state != PlayerState.ATTACKING:
		#updateAnimation()
#
#func start_attack():
	#can_attack = false
	#current_state = PlayerState.ATTACKING
	#anim_player.stop()
	#anim_player.play("primary_attack")
#
#func _on_anim_finished(anim_name: String):
	#if anim_name == "primary_attack":
		#current_state = PlayerState.IDLE
		#can_attack = true
	#
#func take_damage(amount: int) -> void:
	#Globals.enemy_health -= amount
	#if Globals.enemy_health <= 0:
		#Globals.player_wins += 1
		#if Globals.player_wins >= ceil(Globals.MAX_ROUNDS / 2.0):
			#Globals.emit_signal("match_ended", "player")
		#else:
			#Globals.emit_signal("round_ended", "player")
		#queue_free()
		#
#func apply_knockback(knockback_force: Vector2) -> void:
	#velocity.x = knockback_force.x
	#velocity.y = knockback_force.y
	#
##func apply_force(force:Vector2, lift: float = 0) -> void:
	##velocity.x = force.x
	##velocity.y = force.y
	##if lift > 0: 
		##velocity.y = -lift
