class_name HitBox
extends Area2D

@export var damage := 5

func _init() -> void:
	collision_layer = 16
	collision_mask = 0
	
	
