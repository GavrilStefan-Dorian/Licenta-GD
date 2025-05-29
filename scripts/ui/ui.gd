extends CanvasLayer

@onready var player_health: TextureProgressBar = $MarginContainer/PlayerHealth
@onready var enemy_health: TextureProgressBar = $MarginContainer2/EnemyHealth

func _ready():
	player_health.value = Globals.player_health
	enemy_health.value = Globals.enemy_health
	
	Globals.stat_change_player.connect(update_player_hp_bar)
	Globals.stat_change_enemy.connect(update_enemy_hp_bar)
	
func update_player_hp_bar():
	player_health.value = Globals.player_health
	
func update_enemy_hp_bar():
	enemy_health.value = Globals.enemy_health
