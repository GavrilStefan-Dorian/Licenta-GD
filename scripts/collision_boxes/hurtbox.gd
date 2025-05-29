class_name HurtBox
extends Area2D


func _init() -> void:
	collision_layer = 1 << 5
	collision_mask = 1 << 4
	
func _ready() -> void:
	add_to_group("hurtboxes")
	connect("area_entered", _on_area_entered)

func _on_area_entered(hitbox: HitBox) -> void:
	if hitbox == null or not hitbox is HitBox:
		return
		
	
