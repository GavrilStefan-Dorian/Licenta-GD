class_name HurtBox
extends Area2D


func _init() -> void:
	collision_layer = 0
	collision_mask = 16
	
func _ready() -> void:
	connect("area_entered", _on_area_entered)

func _on_area_entered(hitbox: HitBox) -> void:
	if hitbox == null or not hitbox is HitBox:
		return
	if owner.has_method("take_damage"):
		owner.take_damage(hitbox.damage)
		
	
