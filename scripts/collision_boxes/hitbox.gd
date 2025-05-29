class_name HitBox
extends Area2D

func _init() -> void:
	collision_layer = 1 << 4
	collision_mask = 1 << 5
	
	
