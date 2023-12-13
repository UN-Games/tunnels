extends Node
# Main Node, Root of the game

# Instance the main menu on start
func _ready():
	var main_menu = preload("res://scenes/menu/main_menu.tscn")
	add_child(main_menu.instantiate())

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("quit") || event.is_action_pressed("ui_cancel"):
		get_tree().quit()
