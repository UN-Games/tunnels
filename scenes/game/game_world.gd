extends Node3D

@export_range(0, 100) var _coins: int = 20
@export var map_size: Vector2i = Vector2i(50,50)
@export var _mesh_lib: MeshLibrary = null
@export var spawner: PackedScene = null
@export var fortress: PackedScene = null
@export var excavator: PackedScene = null
# export a list of tools/powerups that can be used.
@export var _tools: Array[PackedScene] = []

@onready var _coins_label: Label = %Control/CanvasLayer/Coins
@onready var _rts_camera: RTSCamera = %RTSCamera

#const level1 = preload("res://scenes/game/levels/level1.tscn")

var _ability: int = 0
var _initial_coins_label_text: String = ""
var _fortress: Fortress
var _lifes: int = 100
var _center: Vector2i = map_size * 0.5

const RAYCAST_LENGTH = 1000
const GROUND_PLANE_0 = Plane(Vector3.UP, Vector3(0, 0, 0))

func _enter_tree() -> void:
	# Events.
	Events.connect("excavation_requested", _on_excavation_requested)
	Events.connect("tunnel_requested", _on_tunnel_requested)
	Events.connect("enemy_reached_fortress", _on_enemy_reached_fortress)

func _ready() -> void:
	# Instantiate the level1 scene.
	GridLevel.generate_level(_mesh_lib, Vector2i(), map_size)
	EconomyManager.set_gold(_coins)
	_rts_camera.position = Vector3(map_size.x * 0.5, 0, map_size.y * 0.5 + 5) # TODO: Fix the camera start position (flickering).

	_fortress = fortress.instantiate()
	add_child(_fortress)
	_fortress.build_at(_center, _lifes, Vector2(0.5, 0.5))

	_initial_coins_label_text = _coins_label.text
	#_pop_spawning_point(Vector2i(randi_range(_center.x - 10, _center.x -5), randi_range(_center.y - 10, _center.y -5)), 19, 0.5, 0.2)
	#_pop_spawning_point(Vector2i(randi_range(_center.x + 10, _center.x + 5), randi_range(_center.y - 10, _center.y + -5)), 20, 0.5, 0.2)
	#_pop_spawning_point(Vector2i(randi_range(_center.x - 10, _center.x -5), randi_range(_center.y + 10, _center.y + 5)), 20, 0.5, 0.2)
	#_pop_spawning_point(Vector2i(randi_range(_center.x - 15, _center.x), randi_range(_center.y + 1, _center.y - 1)), 20, 0.5, 0.2)
	await _pop_spawning_point(Vector2i(randi_range(_center.x + 10, _center.x + 5), randi_range(_center.y + 10, _center.y + 5)), 20, 0.5, 0.2)
	GridLevel.spawn_mines(5)
	#await _excavate_path_to(Vector2i(0,0), Vector2i(10,0), 0.1)

func _process(delta: float) -> void:
	_coins_label.text = _initial_coins_label_text + str(EconomyManager.get_gold())

func _physics_process(delta: float) -> void:

	# on left click.
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var ray_result = _raycast()
		if ray_result.size() > 0:
			var co:CollisionObject3D = ray_result.get("collider")
			#print(co.get_groups())

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("select"):
		var ground_point = _get_ground_click_location()
		# check if the tile is empty.
		if !GridLevel.is_tile_empty(ground_point):
			return
		match _ability:
			1:
				if EconomyManager.spend_gold(10) == false:
					return
				GridLevel.explode_to_position(ground_point, Vector2i(5, 5))
			2:
				# spawn a radar (second _tool)
				if EconomyManager.spend_gold(10) == false:
					return
				var radar = _tools[1].instantiate()
				add_child(radar)
				radar.setup(ground_point, Vector2i(7, 7))
				radar.reveal()

			3:
				pass
			_:
				GridLevel.remove_tiles(ground_point)

	if event.is_action_pressed("ability_1"):
		_ability = 1
	if event.is_action_pressed("ability_2"):
		_ability = 2
	if event.is_action_pressed("ability_3"):
		_ability = 3

	# Reload the current scene.
	if event.is_action_pressed("reload"):
		get_tree().reload_current_scene()

	if event.is_action_pressed("speed"):
		Engine.time_scale = 2.5

	if event.is_action_released("speed"):
		Engine.time_scale = 1

func _pop_spawning_point(pos: Vector2i, amount: int = 10, rate: float = 2, speed: float = 2) -> void:
	# clear a small area around the spawning point. explosion of radius 3.

	# create a path pointing the fortress.
	var excavator_inst = excavator.instantiate()
	add_child(excavator_inst)
	excavator_inst.setup(pos, _fortress.get_pos(), speed)

	var spawner_inst = spawner.instantiate()
	add_child(spawner_inst)
	spawner_inst.setup(pos, _fortress.get_pos(), amount, rate)

	await excavator_inst.excavate_path()
	# set the position of the spawner.
	spawner_inst.spawn_enemies()

func _raycast() -> Dictionary:
	var cam = get_viewport().get_camera_3d()
	var space_state = get_world_3d().direct_space_state
	var mouse_pos:Vector2 = get_viewport().get_mouse_position()
	var origin:Vector3 = cam.project_ray_origin(mouse_pos)
	var end:Vector3 = origin + cam.project_ray_normal(mouse_pos) * RAYCAST_LENGTH
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true
	return space_state.intersect_ray(query)

func _on_excavation_requested(pos: Vector2i, size: Vector2i) -> void:
	# instantiate an excavator.
	var excavator_inst = excavator.instantiate()
	add_child(excavator_inst)
	excavator_inst.setup(pos, _fortress.get_pos())
	excavator_inst.excavate_at_position(pos, size)

func _on_tunnel_requested(start: Vector2i, end: Vector2i) -> void:
	var excavator_inst: Excavator = excavator.instantiate()
	add_child(excavator_inst)
	excavator_inst.setup(start, start + end, 0.5)
	excavator_inst.excavate_path()

func _on_enemy_reached_fortress() -> void:
	_lifes -= 1
	Events.emit_signal("lifes_changed", _lifes)
	if _lifes <= 0:
		await get_tree().create_timer(2).timeout
		print("Game Over")
		get_tree().reload_current_scene()
		return

func _get_ground_click_location() -> Vector2i:
	var cam = get_viewport().get_camera_3d()
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_from = cam.project_ray_origin(mouse_pos)
	var ray_to = ray_from + cam.project_ray_normal(mouse_pos) * RAYCAST_LENGTH
	var intersect = GROUND_PLANE_0.intersects_ray(ray_from, ray_to)
	# TODO: check if the click hit a tile using the 3 planes
	# TODO fix the final position
	return Vector2i(floori(intersect.x - (intersect.x * (cam.position.z - 1) * 0.001)),
		floori(intersect.z - (intersect.z * (cam.position.z - 1) * 0.001)))
