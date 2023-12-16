extends Node3D

@export_range(0, 100) var _coins: int = 20
@export var _mesh_lib: MeshLibrary = null
@export var spawner: PackedScene = null
@export var fortress: PackedScene = null

@onready var _coins_label: Label = %Control/CanvasLayer/Coins
@onready var _rts_camera: RTSCamera = %RTSCamera

#const level1 = preload("res://scenes/game/levels/level1.tscn")

var _ability: int = 0
var _initial_coins_label_text: String = ""
var _grid_level: GridLevel
var _path_generator: PathGenerator # TODO: Make this a singleton
var _fortress: Fortress



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# generate a new level
	_grid_level = GridLevel.new(_mesh_lib)
	_path_generator = PathGenerator.new()

	# Instantiate the level1 scene.
	_grid_level._generate_level(Vector2i(), Vector2i(100,100))
	_fortress = fortress.instantiate()
	add_child(_grid_level)
	add_child(_fortress)
	_initial_coins_label_text = _coins_label.text
	Events.connect("path_excavation_requested", _excavate_path_to)
	await _excavate_path_to(Vector2i(0,0), Vector2i(10,randi_range(-5, 5)), 0.1)
	await _pop_spawning_point(Vector2i(-15,-10))

func _process(delta: float) -> void:
	_coins_label.text = _initial_coins_label_text + str(_coins)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("select"):
		# the ability 1 cost 10 coins to be used.
		if _ability == 1 and _coins >= 10:
			_coins -= 10
			_rts_camera._excavate_on_click(_ability)

		else:
			_rts_camera._excavate_on_click(0)

	if event.is_action_pressed("ability_1"):
		_ability = 1
	if event.is_action_pressed("ability_2"):
		_ability = 2
	if event.is_action_pressed("ability_3"):
		_ability = 3

	# Reload the current scene.
	if event.is_action_pressed("reload"):
		get_tree().reload_current_scene()

func _excavate_path_to(start: Vector2i, end: Vector2i, dur: float = 0.1) -> Array[Vector2i]:
	# Generate a path from start to end.
	var pg:Array[Vector2i] = _path_generator.generate_path_to(start, end)
	# Excavate the path. based on the path generated.
	for tile:Vector2i in pg:
		_grid_level.excavate_at_position(tile, Vector2i.ONE, 1)
		await get_tree().create_timer(dur).timeout
	return pg

func _pop_spawning_point(pos: Vector2i, amount: int = 10, rate: int = 2, dur: float = 0.1) -> void:
	# clear a small area around the spawning point. explosion of radius 3.
	Events.emit_signal("explosion_requested", pos, 3)
	# create a path pointing the fortress.
	var path:Array[Vector2i] = await _excavate_path_to(pos, _fortress.get_pos(), dur)

	# creat a 3d curve to move the enemy along the path.
	var curve3D: Curve3D = Curve3D.new()

	# for every point in the path, add a point to the curve.
	for point:Vector2i in path:
		curve3D.add_point(Vector3(point.x + 0.5, 0.5, point.y + 0.5))

	# spawn the amount of enemies. and wait for the rate.
	# instantiate a spawner.
	var spawner_inst = spawner.instantiate()
	add_child(spawner_inst)
	spawner_inst.set_pos(Vector3(pos.x + 0.5, 0.5, pos.y + 0.5))
	spawner_inst.spawn_enemies(curve3D, amount, rate)
