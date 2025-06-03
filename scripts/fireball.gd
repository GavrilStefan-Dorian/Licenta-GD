class_name Fireball
extends Area2D

var speed = 400
var direction = 1  # 1 = right, -1 = left
var damage = 8
var knockback = Vector2(200, -100)
var hitstun = 0.4
var source_character: CharacterBody2D = null
var hit_something = false
var collision_enabled = false  
var animated_sprite: AnimatedSprite2D

func _ready():
	print("Fireball spawned at: ", global_position)
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	animated_sprite = $AnimatedSprite2D
	if animated_sprite:
		animated_sprite.play("fireball")

	collision_layer = 0
	collision_mask = 0
	
	scale.x *= direction 
	
	var collision_timer = get_tree().create_timer(0.15)
	collision_timer.timeout.connect(func():
		collision_layer = 1 << 4
		collision_mask = (1 << 5) | (1 << 4) | 1
		collision_enabled = true
	)
	
	var lifetime_timer = get_tree().create_timer(2.0)
	lifetime_timer.timeout.connect(queue_free)

func _process(delta):
	print("Fireball position: ", global_position, " Direction: ", direction)
	position.x += speed * direction * delta

func _on_area_entered(area):
	if hit_something or not collision_enabled:
		return
		
	if area.get_parent() == source_character:
		return

	if area is Fireball or area.get_parent() is Fireball:
		hit_something = true
		queue_free()
		return
	
	if area.is_in_group("hurtboxes"):
		var target = area.get_parent()
		if target != source_character:
			if target.has_method("take_damage"):
				target.take_damage(damage, knockback * direction, hitstun)
			elif target.get_node_or_null("StateMachineController"):
				var state_machine = target.get_node("StateMachineController").state_machine
				state_machine.transition_to("hurt", {
					"damage": damage,
					"knockback": Vector2(knockback.x * direction, knockback.y),
					"hitstun_duration": hitstun
				})
			
			hit_something = true
			queue_free()

func _on_body_entered(body):
	print("Collision with: ", body.name)
	if hit_something or not collision_enabled:
		return
		
	if body == source_character:
		return
		
	if body is TileMap or "TileMap" in body.get_class():
		hit_something = true
		queue_free()
	else:
		hit_something = true
		queue_free()
