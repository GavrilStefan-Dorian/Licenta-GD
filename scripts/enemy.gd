extends CharacterBody2D

@onready var animations = $AnimatedSprite2D

const SPEED = 400.0
const JUMP_VELOCITY = -350.0


func handleInput():
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

		
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	handleInput()
	move_and_slide()

func take_damage(amount: int) -> void:
	Globals.enemy_health -= amount;
	if Globals.enemy_health <= 0:
		queue_free()
