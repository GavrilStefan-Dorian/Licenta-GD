extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Globals:
		Globals.reset_game_state()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# print("Enemy at %s, Collision at %s" % [$Enemy.position, $Enemy/CollisionShape2D.position])
	pass
