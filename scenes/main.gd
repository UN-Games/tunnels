extends Node
# Main Node, Root of the game

# Instance the main menu on start
func _ready():
	var main_menu = preload("res://scenes/menu/main_menu.tscn")
	add_child(main_menu.instantiate())
