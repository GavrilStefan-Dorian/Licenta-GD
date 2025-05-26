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

@onready var animation_player = $AnimationPlayer
@onready var animated_sprite = $AnimatedSprite2D
@onready var hitbox = $HitBox
@onready var camera = $"../Background/Camera2D"
@onready var hit_spark = $HitSpark

func _ready():
	add_to_group("players")
	
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
		enemy.apply_knockback(Vector2(current_attack_knockback.x * facing_direction, current_attack_knockback.y))
		# Prevent multi-hit per swing
		current_attack_damage = 0

	
func take_damage(amount: int) -> void:
	if is_invincible or is_guarding:
		return
	Globals.player_health -= amount
	if Globals.player_health <= 0:
		Globals.enemy_wins += 1
		if Globals.player_wins >= ceil(Globals.MAX_ROUNDS / 2.0):
			Globals.emit_signal("match_ended", "player")
		else:
			Globals.emit_signal("round_ended", "player")
		queue_free()		

func apply_knockback(knockback_force: Vector2) -> void:
	if is_invincible or is_guarding:
		return
	if get_node_or_null("StateMachine"):
		get_node("StateMachine")._transition_to_next_state("Knockback", {
			"knockback_velocity": knockback_force
		})
	else:
		velocity = knockback_force  # Fallback

#
#enum PlayerState { IDLE, WALKING, ATTACKING, GUARDING, DASHING, CASTING, GRABBING }
#var current_state := PlayerState.IDLE
#var can_dash := true
#var can_cast := true
#var is_guarding := false
#var is_invincible := false
#var dash_timer := 0.0
#var facing_direction := 1
#var super_meter := 0
#const MAX_SUPER_METER = 100
#
## Attack properties
#@onready var guard_aura
#@onready var dash_trail 
#

#func handleInput():
	## Only handle movement if not in restricted states
	#if current_state in [PlayerState.ATTACKING, PlayerState.GUARDING, PlayerState.DASHING, PlayerState.CASTING, PlayerState.GRABBING]:
		#velocity.x = move_toward(velocity.x, 0, SPEED * 2) # Quick stop when in these states
		#return
	#
	#var direction := Input.get_axis("move_left", "move_right")
	#if direction != 0:
		#facing_direction = sign(direction)
		#velocity.x = direction * SPEED
	#else:
		#velocity.x = move_toward(velocity.x, 0, SPEED)
#
#func handleCombatInput():
	## Debug prints
	#if Input.is_action_just_pressed("primary_action"):
		#print("Primary action pressed! can_attack: ", can_attack, " state: ", current_state)
	#
	## Prevent any combat actions during guarding (except releasing guard)
	#if current_state == PlayerState.GUARDING:
		#if Input.is_action_just_released("guard"):
			#stop_guard()
		#return
	#
	## Try multiple input methods - use whatever key you're pressing
	## Test with common keys first
	#if Input.is_action_just_pressed("ui_accept") and can_attack and current_state not in [PlayerState.ATTACKING, PlayerState.CASTING, PlayerState.GRABBING]:
		#print("UI Accept attack!")
		#start_jab()
	#
	## Primary action (basic attack)
	#if Input.is_action_just_pressed("primary_action") and can_attack and current_state not in [PlayerState.ATTACKING, PlayerState.CASTING, PlayerState.GRABBING]:
		#print("Primary action attack!")
		#start_jab()
	#
	## Test with keyboard keys directly
	#if Input.is_key_pressed(KEY_Z) and can_attack and current_state not in [PlayerState.ATTACKING, PlayerState.CASTING, PlayerState.GRABBING]:
		#print("Z key attack!")
		#start_jab()
	#
	## Jab - Quick, low damage attack
	#if Input.is_action_just_pressed("jab") and can_attack and current_state not in [PlayerState.ATTACKING, PlayerState.CASTING, PlayerState.GRABBING]:
		#print("Jab attack!")
		#start_jab()
	#
	## Heavy blow - Slower, high damage attack
	#if Input.is_action_just_pressed("heavy_blow") and can_attack and current_state not in [PlayerState.ATTACKING, PlayerState.CASTING, PlayerState.GRABBING]:
		#print("Heavy blow attack!")
		#start_heavy_blow()
	#
	## Uppercut - Anti-air attack with upward knockback
	#if Input.is_action_just_pressed("upper_cut") and can_attack and current_state not in [PlayerState.ATTACKING, PlayerState.CASTING, PlayerState.GRABBING]:
		#print("Uppercut attack!")
		#start_uppercut()
	#
	## Guard
	#if Input.is_action_pressed("guard") and current_state not in [PlayerState.ATTACKING, PlayerState.DASHING, PlayerState.CASTING, PlayerState.GRABBING]:
		#start_guard()
	#elif Input.is_action_just_released("guard"):
		#stop_guard()
	#
	## Dash
	#if Input.is_action_just_pressed("dash") and can_dash and current_state not in [PlayerState.ATTACKING, PlayerState.CASTING, PlayerState.GRABBING]:
		#start_dash()
	#
	## Grapple
	#if Input.is_action_just_pressed("grapple") and can_attack and current_state not in [PlayerState.ATTACKING, PlayerState.CASTING, PlayerState.DASHING]:
		#start_grapple()
	#
	## Super move
	#if Input.is_action_just_pressed("super") and super_meter >= MAX_SUPER_METER and can_cast:
		#start_super_move()
#
#func updateAnimation():
	#if current_state in [PlayerState.ATTACKING, PlayerState.GUARDING, PlayerState.DASHING, PlayerState.CASTING, PlayerState.GRABBING]:
		#return
		#
	#if is_zero_approx(velocity.length()):
		#current_state = PlayerState.IDLE
	#else:
		#if not is_zero_approx(velocity.x):
			#current_state = PlayerState.WALKING
#
#func _physics_process(delta: float) -> void:
	#if not is_on_floor():
		#velocity += get_gravity() * delta
	#
	## Jump (disabled during certain states)
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor() and current_state not in [PlayerState.ATTACKING, PlayerState.CASTING, PlayerState.GRABBING]:
		#velocity.y = JUMP_VELOCITY
	#
	## Handle dash timer
	#if current_state == PlayerState.DASHING:
		#dash_timer -= delta
		#if dash_timer <= 0:
			#stop_dash()
	#
	## Handle attack timer
	#if current_state == PlayerState.ATTACKING:
		#attack_timer -= delta
		#if attack_timer <= 0:
			#end_attack()
	#
	#handleInput()
	#handleCombatInput()
	#move_and_slide()
	#updateAnimation()
#
## JAB - Quick, light attack
#func start_jab():
	#print("JAB STARTED!")
	#can_attack = false
	#current_state = PlayerState.ATTACKING
	#attack_timer = 0.3
	#current_attack_damage = 8
	#current_attack_knockback = Vector2(150 * facing_direction, -50)
	#
	#create_hit_effect("white", 0.5)
	#create_attack_hitbox()
#
## HEAVY BLOW - Slow, powerful attack
#func start_heavy_blow():
	#print("HEAVY BLOW STARTED!")
	#can_attack = false
	#current_state = PlayerState.ATTACKING
	#attack_timer = 0.6
	#current_attack_damage = 20
	#current_attack_knockback = Vector2(400 * facing_direction, -100)
	#
	#create_hit_effect("red", 1.0)
	#screen_shake(0.2, 10)
	#create_attack_hitbox()
#
## UPPERCUT - Anti-air with upward knockback
#func start_uppercut():
	#print("UPPERCUT STARTED!")
	#can_attack = false
	#current_state = PlayerState.ATTACKING
	#attack_timer = 0.4
	#current_attack_damage = 15
	#current_attack_knockback = Vector2(100 * facing_direction, -300)
	#
	#create_hit_effect("yellow", 0.7)
	#create_attack_hitbox()
#
## GRAPPLE - Close range grab with pull effect
#func start_grapple():
	#current_state = PlayerState.GRABBING
	#can_attack = false
	#attack_timer = 0.5
	#
	## Check for enemies in grab range
	#var space_state = get_world_2d().direct_space_state
	#var query = PhysicsRayQueryParameters2D.create(
		#position,
		#position + Vector2(80 * facing_direction, 0)
	#)
	#var result = space_state.intersect_ray(query)
	#
	#if result and result.collider.is_in_group("enemies"):
		#var enemy = result.collider
		#create_hit_effect("purple", 1.0)
		#
		## Pull enemy towards player before dealing damage
		#if enemy.has_method("apply_knockback"):
			#var pull_force = Vector2(-200 * facing_direction, -50) # Pull towards player
			#enemy.apply_knockback(pull_force)
		#
		## Deal damage after a short delay
		#await get_tree().create_timer(0.2).timeout
		#if enemy and is_instance_valid(enemy):
			#if enemy.has_method("take_damage"):
				#enemy.take_damage(18)
			## Then push away
			#if enemy.has_method("apply_knockback"):
				#enemy.apply_knockback(Vector2(300 * facing_direction, -100))
#
#func start_guard():
	#if current_state == PlayerState.GUARDING:
		#return
		#
	#current_state = PlayerState.GUARDING
	#is_guarding = true
	#is_invincible = true
	#
	## Visual feedback for guard
	#animated_sprite.modulate = Color(0.5, 0.5, 1.0)
	#if guard_aura:
		#guard_aura.emitting = true
#
#func stop_guard():
	#if current_state != PlayerState.GUARDING:
		#return
		#
	#is_guarding = false
	#is_invincible = false
	#animated_sprite.modulate = Color.WHITE
	#if guard_aura:
		#guard_aura.emitting = false
	#current_state = PlayerState.IDLE
#
#func start_dash():
	#if not can_dash:
		#return
		#
	#can_dash = false
	#current_state = PlayerState.DASHING
	#dash_timer = DASH_DURATION
	#
	#velocity.x = DASH_SPEED * facing_direction
	#
	#if dash_trail:
		#dash_trail.emitting = true
	#
	## Reset dash cooldown
	#await get_tree().create_timer(1.0).timeout
	#can_dash = true
#
#func stop_dash():
	#current_state = PlayerState.IDLE
	#if dash_trail:
		#dash_trail.emitting = false
#
#func start_super_move():
	#if super_meter < MAX_SUPER_METER:
		#return
		#
	#super_meter = 0
	#can_cast = false
	#current_state = PlayerState.CASTING
	#
	#screen_flash()
	#screen_shake(0.5, 20)
	#
	#Engine.time_scale = 0.3
	#await get_tree().create_timer(0.5).timeout
	#Engine.time_scale = 1.0
	#
	#create_super_hitbox()
	#
	#await get_tree().create_timer(0.5).timeout
	#can_cast = true
	#current_state = PlayerState.IDLE
#
#func end_attack():
	#can_attack = true
	#current_state = PlayerState.IDLE
	#current_attack_damage = 0
	#current_attack_knockback = Vector2.ZERO
#
#func create_attack_hitbox():
	#print("Creating attack hitbox!")
	#var area = Area2D.new()
	#var collision = CollisionShape2D.new()
	#var shape = RectangleShape2D.new()
	#
	## Adjust hitbox size based on attack type
	#if current_state == PlayerState.GRABBING:
		#shape.size = Vector2(80, 60)
	#else:
		#shape.size = Vector2(60, 40)
	#
	#collision.shape = shape
	#area.add_child(collision)
	#
	## Position hitbox in front of player
	#area.position = position + Vector2(30 * facing_direction, -10)
	#get_parent().add_child(area)
	#
	## Create visual indicator for the hitbox (temporary)
	#var visual = ColorRect.new()
	#visual.size = shape.size
	#visual.color = Color.RED
	#visual.color.a = 0.5
	#visual.position = -shape.size / 2  # Center the visual
	#area.add_child(visual)
	#
	## Connect hit detection
	#area.body_entered.connect(_on_attack_hit)
	#area.area_entered.connect(_on_attack_hit_area)  # Also detect areas
	#
	#print("Hitbox created at position: ", area.position, " with size: ", shape.size)
	#
	## Remove hitbox after short duration
	#await get_tree().create_timer(0.15).timeout
	#if is_instance_valid(area):
		#print("Removing hitbox")
		#area.queue_free()
#
#func _on_attack_hit(body):
	#print("Hit detected on body: ", body.name)
	#if body.is_in_group("enemies") and current_state in [PlayerState.ATTACKING, PlayerState.GRABBING]:
		#print("Hitting enemy: ", body.name, " for ", current_attack_damage, " damage")
		#if body.has_method("take_damage"):
			#body.take_damage(current_attack_damage)
		#
		#if body.has_method("apply_knockback") and current_attack_knockback != Vector2.ZERO:
			#body.apply_knockback(current_attack_knockback)
		#
		## Build super meter
		#super_meter = min(super_meter + 10, MAX_SUPER_METER)
		#print("Super meter: ", super_meter)
#
#func _on_attack_hit_area(area):
	#print("Hit detected on area: ", area.name)
	#var body = area.get_parent()
	#if body and body.is_in_group("enemies") and current_state in [PlayerState.ATTACKING, PlayerState.GRABBING]:
		#print("Hitting enemy area: ", body.name, " for ", current_attack_damage, " damage")
		#if body.has_method("take_damage"):
			#body.take_damage(current_attack_damage)
		#
		#if body.has_method("apply_knockback") and current_attack_knockback != Vector2.ZERO:
			#body.apply_knockback(current_attack_knockback)
		#
		## Build super meter
		#super_meter = min(super_meter + 10, MAX_SUPER_METER)
		#print("Super meter: ", super_meter)
#
#func create_hit_effect(color: String, intensity: float):
	#if not hit_spark:
		#return
		#
	#match color:
		#"white":
			#hit_spark.modulate = Color.WHITE
		#"red":
			#hit_spark.modulate = Color.RED
		#"yellow":
			#hit_spark.modulate = Color.YELLOW
		#"purple":
			#hit_spark.modulate = Color.MAGENTA
#
#func screen_shake(duration: float, strength: float):
	#if camera:
		#var tween = create_tween()
		#var original_pos = camera.position
		#
		#for i in range(int(duration * 60)):
			#var shake_offset = Vector2(
				#randf_range(-strength, strength),
				#randf_range(-strength, strength)
			#)
			#tween.tween_callback(func(): camera.position = original_pos + shake_offset)
		#
		#tween.tween_callback(func(): camera.position = original_pos)
#
#func screen_flash():
	#var flash = ColorRect.new()
	#flash.color = Color.WHITE
	#flash.color.a = 0.8
	#flash.size = get_viewport().size
	#get_tree().current_scene.add_child(flash)
	#
	#var tween = create_tween()
	#tween.tween_property(flash, "color:a", 0.0, 0.3)
	#tween.tween_callback(flash.queue_free)
#
#func create_super_hitbox():
	#var area = Area2D.new()
	#var collision = CollisionShape2D.new()
	#var shape = RectangleShape2D.new()
	#
	#shape.size = Vector2(400, 200)
	#collision.shape = shape
	#area.add_child(collision)
	#
	#area.position = position
	#get_parent().add_child(area)
	#
	#area.body_entered.connect(func(body):
		#if body.is_in_group("enemies"):
			#if body.has_method("take_damage"):
				#body.take_damage(50)
			#create_hit_effect("red", 2.0)
	#)
	#
	#await get_tree().create_timer(0.2).timeout
	#if is_instance_valid(area):
		#area.queue_free()
#
#
#func take_damage(amount: int) -> void:
	#if is_invincible:
		#return
		#
	#Globals.player_health -= amount
	#if Globals.player_health <= 0:
		#Globals.enemy_wins += 1
		#if Globals.enemy_wins >= ceil(Globals.MAX_ROUNDS / 2.0):
			#Globals.emit_signal("match_ended", "enemy")
		#else:
			#Globals.emit_signal("round_ended", "enemy")
		#queue_free()
