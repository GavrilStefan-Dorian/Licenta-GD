class_name Fireball
extends HitBox

var speed = 400
var direction = 1  # 1 = right, -1 = left
var damage = 8
var knockback = Vector2(200, -100)
var hitstun = 0.4
var source_character: CharacterBody2D = null
var animated_sprite: AnimatedSprite2D

func _init() -> void:
	super._init()
	collision_mask |= (1 << 4)

func _ready():
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	animated_sprite = $AnimatedSprite2D
	if animated_sprite:
		animated_sprite.play("fireball")

	scale.x *= direction 

	var lifetime_timer = get_tree().create_timer(2.0)
	lifetime_timer.timeout.connect(queue_free)

func _process(delta):
	position.x += speed * direction * delta

func _on_area_entered(area):
	if area.get_parent() == source_character:
		return

	if area is Fireball or area.get_parent() is Fireball:
		queue_free()
		return
	
	if area.is_in_group("hurtboxes"):
		var target = area.get_parent()
		if target != source_character:
			if target.is_guarding:
				var target_state_machine = target.get_node("StateMachineController").state_machine
				target_state_machine.transition_to("hurt", {
					"damage": 0,
					"knockback": Vector2(30 * source_character.facing_direction, 0), 
					"hitstun_duration": target.GUARD_STUN_DURATION,
					"is_guard_hit": true
				})
				queue_free()
				return

			if target.is_invincible: 
				queue_free()
				return
			
			if target.has_method("take_damage"):
				target.take_damage(damage, knockback * direction, hitstun)
			elif target.get_node_or_null("StateMachineController"):
				var state_machine = target.get_node("StateMachineController").state_machine
				state_machine.transition_to("hurt", {
					"damage": damage,
					"knockback": Vector2(knockback.x * direction, knockback.y),
					"hitstun_duration": hitstun
				})
			
			queue_free()

func _on_body_entered(body):
	print("Collision with: ", body.name)
		
	if body == source_character:
		return
		
	if body is TileMap or "TileMap" in body.get_class():
		queue_free()
	else:
		queue_free()
