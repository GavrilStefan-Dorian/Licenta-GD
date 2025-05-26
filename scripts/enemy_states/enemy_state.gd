class_name EnemyState extends State

const IDLE = "IdleEnemy"
const WALKING = "WalkingEnemy"
const AIR = "AirEnemy"
const ATTACK = "AttackEnemy"
#const FALLING = "Falling" 
const GRAPPLE = "GrappleEnemy"
const GUARD = "GuardEnemy"
const DASH = "DashingEnemy"

var enemy: Enemy


func _ready() -> void:
	enemy = find_parent("Enemy")
	if enemy:
		await enemy.ready
	assert(enemy != null, "The EnemyState state type must be used only in the enemy scene. It needs the owner to be a Enemy node.")
