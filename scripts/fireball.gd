class_name Fireball
extends RigidBody2D

const FIREBALL_SPEED = 300.0
const LIFETIME = 3.0
const DAMAGE = 15

var direction := 1
var has_hit := false

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D
@onready var fire_trail = $FireTrail
@onready var area_detector = $Area2D

func _ready():
	gravity_scale = 0
	linear_damp = 0
	
	linear_velocity = Vector2(FIREBALL_SPEED * direction, 0)
	
	if area_detector:
		area_detector.body_entered.connect(_on_body_entered)
		area_detector.area_entered.connect(_on_area_entered)
	
	if fire_trail:
		fire_trail.start_fire_trail()
	
	var timer = get_tree().create_timer(LIFETIME)
	timer.timeout.connect(explode)
	
	add_to_group("projectiles")

func _on_body_entered(body):
	if has_hit:
		return
		
	if body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(DAMAGE)
		explode()
	
	elif not body.is_in_group("players"):
		explode()

func _on_area_entered(area):
	if has_hit:
		return
		
	if area.is_in_group("hitboxes"):
		explode()

func explode():
	if has_hit:
		return
		
	has_hit = true
	linear_velocity = Vector2.ZERO
	if sprite:
		sprite.visible = false
	if fire_trail:
		fire_trail.stop_fire_trail()
	create_explosion()
	if collision:
		collision.set_deferred("disabled", true)
	var timer = get_tree().create_timer(0.5)
	timer.timeout.connect(queue_free)

func create_explosion():
	"""Create fireball explosion effect"""
	var explosion = CPUParticles2D.new()
	add_child(explosion)
	explosion.amount = 25
	explosion.lifetime = 0.6
	explosion.one_shot = true
	explosion.explosiveness = 1.0
	explosion.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	explosion.emission_sphere_radius = 15.0
	explosion.direction = Vector2(0, -1)
	explosion.spread = 45.0
	explosion.initial_velocity_min = 100.0
	explosion.initial_velocity_max = 200.0
	
	explosion.gravity = Vector2(0, 200)
	explosion.linear_accel_min = -50.0
	explosion.linear_accel_max = 50.0
	explosion.scale_amount_min = 0.5
	explosion.scale_amount_max = 1.5
	explosion.color = Color(1.0, 0.6, 0.2, 0.9)
	
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1.0, 1.0, 0.8, 1.0))
	gradient.add_point(0.3, Color(1.0, 0.6, 0.2, 0.8))
	gradient.add_point(0.7, Color(0.8, 0.3, 0.1, 0.4))
	gradient.add_point(1.0, Color(0.4, 0.2, 0.1, 0.0))
	explosion.color_ramp = gradient
	
	explosion.emitting = true
	create_screen_shake()

func create_screen_shake():
	"""Create screen shake effect for explosion"""
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return
	
	var tween = create_tween()
	var original_pos = camera.position
	var shake_strength = 8.0
	var shake_duration = 0.2
	
	for i in range(int(shake_duration * 60)):
		var shake_offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
		tween.tween_callback(func(): camera.position = original_pos + shake_offset)
		tween.tween_delay(1.0/60.0)
	
	tween.tween_callback(func(): camera.position = original_pos)
