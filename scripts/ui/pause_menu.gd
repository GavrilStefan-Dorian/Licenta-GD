extends Control

var is_visible := false

func _ready():
	visible = false 
	
func resume():
	is_visible = false
	get_tree().paused = false
	$AnimationPlayer.play_backwards("blur")
	await $AnimationPlayer.animation_finished
	visible = false 

func pause():
	is_visible = true
	visible = true
	get_tree().paused = true
	$AnimationPlayer.play("blur")

func testEsc():
	if Input.is_action_just_pressed("escape"):
		if is_visible:
			resume()
		else:
			pause()

func _on_resume_pressed() -> void:
	resume()

func _on_restart_pressed() -> void:
	resume()
	get_tree().change_scene_to_file(get_tree().current_scene.scene_file_path)

func _on_quit_pressed() -> void:
	get_tree().quit()
	
func _process(delta):
	testEsc()
