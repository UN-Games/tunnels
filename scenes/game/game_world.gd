extends Node3D

@export_range(0, 100) var _coins: int = 20
@export var _mesh_lib: MeshLibrary = null

@onready var _coins_label: Label = %Control/CanvasLayer/Coins
@onready var _rts_camera: RTSCamera = %RTSCamera

const fortress = preload("res://scenes/game/entities/fortress.tscn")
#const level1 = preload("res://scenes/game/levels/level1.tscn")

var _path_generator: PathGenerator
var _ability: int = 0
var _initial_coins_label_text: String = ""
var _grid_level: GridLevel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# generate a new level
	_grid_level = GridLevel.new(_mesh_lib)
	_path_generator = PathGenerator.new()
	# Instantiate the level1 scene.
	_grid_level._generate_level(Vector2i(), Vector2i(20,10))
	add_child(_grid_level)
	add_child(fortress.instantiate())
	_initial_coins_label_text = _coins_label.text
	_excavate_path()


func _process(delta: float) -> void:
	_coins_label.text = _initial_coins_label_text + str(_coins)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("select"):
		# the ability 1 cost 10 coins to be used.
		if _ability == 1 and _coins >= 10:
			_coins -= 10
			_rts_camera._excavate_on_click(_ability)

	if event.is_action_pressed("ability_1"):
		_ability = 1
	if event.is_action_pressed("ability_2"):
		_ability = 2
	if event.is_action_pressed("ability_3"):
		_ability = 3

func _excavate_path() -> void:
	var pg:Array[Vector2i] = _path_generator.generate_path(Vector2i(-5,-5), Vector2i(0,0))
		# if not, emit the signal to excavate the path.
	for tile:Vector2i in pg:
		_grid_level.excavate_to_position(tile)
