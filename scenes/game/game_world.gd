extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Instantiate the level1 scene.
	var level1 = preload("res://scenes/game/levels/level1.tscn")
	add_child(level1.instantiate())
