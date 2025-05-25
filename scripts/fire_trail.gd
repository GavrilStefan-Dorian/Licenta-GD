class_name FireTrail extends CPUParticles2D

func _ready():
	emitting = false
	amount = 15
	lifetime = 0.8
	explosiveness = 0.1
	
	# Trail behind fireball
	emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	emission_sphere_radius = 8.0
	direction = Vector2(-1, 0)  # Opposite to movement
	spread = 25.0
	initial_velocity_min = 30.0
	initial_velocity_max = 60.0
	
	# Fire physics
	gravity = Vector2(0, -20)  # Slight upward drift
	linear_accel_min = -20.0
	linear_accel_max = 20.0
	
	# Visual
	scale_amount_min = 0.3
	scale_amount_max = 0.8
	color = Color(1.0, 0.7, 0.3, 0.8)
	
	# Fire color gradient
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1.0, 1.0, 0.9, 0.9))
	gradient.add_point(0.3, Color(1.0, 0.7, 0.3, 0.8))
	gradient.add_point(0.7, Color(1.0, 0.4, 0.1, 0.5))
	gradient.add_point(1.0, Color(0.6, 0.2, 0.0, 0.0))
	color_ramp = gradient

func start_fire_trail():
	emitting = true

func stop_fire_trail():
	emitting = false
