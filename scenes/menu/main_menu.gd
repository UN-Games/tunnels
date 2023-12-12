extends Control



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Grab the focus of the start button
	$MarginContainer/VBoxContainer/Play.grab_focus()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game/game_world.tscn")

func _on_options_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menu/options/options.tscn")


func _on_quit_pressed() -> void:
	# quit the game
	get_tree().quit()
