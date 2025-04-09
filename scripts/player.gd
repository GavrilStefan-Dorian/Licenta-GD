extends CharacterBody2D


const SPEED = 400.0
const JUMP_VELOCITY = -350.0

@onready var animations = $AnimatedSprite2D

func handleInput():
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED 
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

func updateAnimation():
	if velocity.length() == 0:
		animations.animation = "idle"
	else:
		if velocity.x > 0: animations.animation = "walking"
		
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	handleInput()
	move_and_slide()
	updateAnimation()
