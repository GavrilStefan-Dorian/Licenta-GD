extends CanvasLayer

@onready var player_health: TextureProgressBar = $MarginContainer/PlayerHealth
@onready var enemy_health: TextureProgressBar = $MarginContainer2/EnemyHealth
@onready var timer = $MarginContainer/PlayerHealth/Timer
@onready var damage_bar = $MarginContainer/PlayerHealth/DamageBar

@onready var damage_bar_enemy = $MarginContainer2/EnemyHealth/DamageBar
@onready var timer_enemy = $MarginContainer2/EnemyHealth/Timer

func _ready():
	player_health.value = Globals.player_health
	enemy_health.value = Globals.enemy_health
	
	Globals.stat_change_player.connect(update_player_hp_bar)
	Globals.stat_change_enemy.connect(update_enemy_hp_bar)
	
func update_player_hp_bar():
	if Globals.player_health < player_health.value:
		timer.start() 
	else:
		damage_bar.value = Globals.player_health

	player_health.value = Globals.player_health
	
func update_enemy_hp_bar():
	if Globals.enemy_health < enemy_health.value:
		timer_enemy.start() 
	else:
		damage_bar_enemy.value = Globals.enemy_health
		
	enemy_health.value = Globals.enemy_health

func _on_timer_timeout() -> void:
	damage_bar.value = player_health.value

func _on_enemy_timer_timeout() -> void:
	damage_bar_enemy.value = enemy_health.value