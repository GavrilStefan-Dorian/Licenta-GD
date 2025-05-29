extends CanvasLayer

@onready var round_label = $Banner/MarginContainer/VBoxContainer/RoundLabel
@onready var status_label = $Banner/MarginContainer/VBoxContainer/StatusLabel
@onready var anim_player = $AnimationPlayer

func show_round_start(round_num: int):
	round_label.text = "ROUND %d/3" % round_num
	status_label.text = "FIGHT!"
	anim_player.play("show_banner")
	await anim_player.animation_finished
	await get_tree().create_timer(1.5).timeout
	anim_player.play("hide_banner")

func show_round_end(winner: String):
	status_label.text = "%s WINS ROUND!" % winner.to_upper()
	anim_player.play("pulse_banner")
	await anim_player.animation_finished
	await get_tree().create_timer(2.0).timeout
	anim_player.play("hide_banner")

func show_match_end(winner: String):
	round_label.text = ""
	status_label.text = "%s WINS THE MATCH!" % winner.to_upper()
	anim_player.play("celebrate")
	await anim_player.animation_finished
