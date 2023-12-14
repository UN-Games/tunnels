extends Node3D

const fortress = preload("res://scenes/game/entities/fortress.tscn")
const level1 = preload("res://scenes/game/levels/level1.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Instantiate the level1 scene.
	add_child(level1.instantiate())
	add_child(fortress.instantiate())
