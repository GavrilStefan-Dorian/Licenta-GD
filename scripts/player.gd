extends CharacterBody2D

const SPEED = 400.0
const JUMP_VELOCITY = -350.0

enum PlayerState { IDLE, WALKING, ATTACKING }
var current_state := PlayerState.IDLE
var can_attack := true

@onready var anim_player = $AnimationPlayer
@onready var animated_sprite = $AnimatedSprite2D  # Still exists for sprite storage

func _ready():
	anim_player.animation_finished.connect(_on_anim_finished)

func handleInput():
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
		#animated_sprite.flip_h = direction < 0 	
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

func updateAnimation():
	if current_state == PlayerState.ATTACKING:
		return
		
	if velocity.length() == 0:
		if anim_player.current_animation != "idle":
			anim_player.play("idle")
		current_state = PlayerState.IDLE
	else:
		if velocity.x != 0 and anim_player.current_animation != "walking":
			anim_player.play("walking")
			current_state = PlayerState.WALKING

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and current_state != PlayerState.ATTACKING:
		velocity.y = JUMP_VELOCITY
		
	if Input.is_action_just_pressed("primary_action") and can_attack:
		start_attack()

	handleInput()
	move_and_slide()
	
	if current_state != PlayerState.ATTACKING:
		updateAnimation()

func start_attack():
	can_attack = false
	current_state = PlayerState.ATTACKING
	anim_player.play("primary_attack")

func _on_anim_finished(anim_name: String):
	if anim_name == "primary_attack":
		current_state = PlayerState.IDLE
		can_attack = true
