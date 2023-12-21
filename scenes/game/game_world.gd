extends Node3D

@export_range(0, 100) var _coins: int = 20
@export var _mesh_lib: MeshLibrary = null
@export var spawner: PackedScene = null
@export var fortress: PackedScene = null
@export var excavator: PackedScene = null

@onready var _coins_label: Label = %Control/CanvasLayer/Coins
@onready var _rts_camera: RTSCamera = %RTSCamera

#const level1 = preload("res://scenes/game/levels/level1.tscn")

var _ability: int = 0
var _initial_coins_label_text: String = ""
var _fortress: Fortress
var _lifes: int = 10

const RAYCAST_LENGTH = 1000

# On enter the scene tree.
func _enter_tree() -> void:
	# Events.
	Events.connect("excavation_requested", _on_excavation_requested)
	Events.connect("tunnel_requested", _on_tunnel_requested)
	Events.connect("enemy_reached_fortress", _on_enemy_reached_fortress)

func _ready() -> void:

	# Instantiate the level1 scene.
	GridLevel.generate_level(_mesh_lib, Vector2i(), Vector2i(50,50))

	_fortress = fortress.instantiate()
	add_child(_fortress)

	_pop_spawning_point(Vector2i(-10,randi_range(-10,0)), 20, 1, 0.2) # TODO: Fix bug when Y is > 0.

	_initial_coins_label_text = _coins_label.text
	#await _excavate_path_to(Vector2i(0,0), Vector2i(10,0), 0.1)

func _process(delta: float) -> void:
	_coins_label.text = _initial_coins_label_text + str(_coins)

func _physics_process(delta: float) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var space_state = get_world_3d().direct_space_state
		var mouse_pos:Vector2 = get_viewport().get_mouse_position()
		var origin:Vector3 = _rts_camera.camera.project_ray_origin(mouse_pos)
		var end:Vector3 = origin + _rts_camera.camera.project_ray_normal(mouse_pos) * RAYCAST_LENGTH
		var query = PhysicsRayQueryParameters3D.create(origin, end)
		query.collide_with_areas = true
		var rayResult:Dictionary = space_state.intersect_ray(query)
		if rayResult.size() > 0:
			print(rayResult)
			var co:CollisionObject3D = rayResult.get("collider")
			print(co.get_groups())

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

func _pop_spawning_point(pos: Vector2i, amount: int = 10, rate: float = 2, speed: float = 2) -> void:
	# clear a small area around the spawning point. explosion of radius 3.
	GridLevel.explode_to_position(pos, 3)
	# create a path pointing the fortress.
	var excavator_inst = excavator.instantiate()
	add_child(excavator_inst)
	excavator_inst.setup(pos, _fortress.get_pos(), speed)

	var spawner_inst = spawner.instantiate()
	add_child(spawner_inst)
	spawner_inst.position = Vector3(pos.x + 0.5, 0.5, pos.y + 0.5)
	await excavator_inst.excavate_path()
	# set the position of the spawner.
	spawner_inst.spawn_enemies(_fortress.get_pos(), amount, rate)

func _on_excavation_requested(pos: Vector2i, size: Vector2i) -> void:
	# instantiate an excavator.
	var excavator_inst = excavator.instantiate()
	add_child(excavator_inst)
	excavator_inst.setup(pos, _fortress.get_pos())
	excavator_inst.excavate_at_position(pos, size)

func _on_tunnel_requested(start: Vector2i, end: Vector2i) -> void:
	var excavator_inst: Excavator = excavator.instantiate()
	add_child(excavator_inst)
	excavator_inst.setup(start, end, 0.1)
	excavator_inst.excavate_path()

func _on_enemy_reached_fortress() -> void:
	if _lifes <= 0:
		await get_tree().create_timer(2).timeout
		get_tree().reload_current_scene()
		return
	_lifes -= 1
	Events.emit_signal("lifes_changed", _lifes)
