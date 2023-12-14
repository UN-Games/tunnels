extends Node3D

@export_range(0, 100) var _coins: int = 20

@onready var _coins_label: Label = %Control/CanvasLayer/Coins

const fortress = preload("res://scenes/game/entities/fortress.tscn")
const level1 = preload("res://scenes/game/levels/level1.tscn")

var _ability: int = 0
var _initial_coins_label_text: String = ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Instantiate the level1 scene.
	add_child(level1.instantiate())
	add_child(fortress.instantiate())
	_initial_coins_label_text = _coins_label.text

func _process(delta: float) -> void:
	_coins_label.text = _initial_coins_label_text + str(_coins)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("select"):
		# the ability 1 cost 10 coins to be used.
		if _ability == 1 and _coins >= 10:
			_coins -= 10
			Events.emit_signal("click_selection_requested", _ability)

	if event.is_action_pressed("ability_1"):
		_ability = 1
	if event.is_action_pressed("ability_2"):
		_ability = 2
	if event.is_action_pressed("ability_3"):
		_ability = 3
