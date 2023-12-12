extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Grab the volume slider focus
	$MarginContainer/VBoxContainer/Volume.grab_focus();


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_volume_pressed() -> void:
	pass # Replace with function body.


func _on_back_pressed() -> void:
	# Go back to the main menu
	get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn");
