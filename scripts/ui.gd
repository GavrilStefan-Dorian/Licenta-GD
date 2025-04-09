extends CanvasLayer

@onready var player_health: TextureProgressBar = $MarginContainer/PlayerHealth

func update_player_hp_bar():
	player_health.value = Globals.player_health
