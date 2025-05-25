class_name HitBox
extends Area2D

#@export var damage := 5

func _init() -> void:
	collision_layer = 1 << 4
	collision_mask = 1 << 5
	
	
