extends Node3D
class_name Excavator

@onready var _path_3d: Path3D = %Path3D
@onready var _path_follow_3d: PathFollow3D = %Path3D/PathFollow3D
@onready var _tunnel_machine: Area3D = %Path3D/PathFollow3D/TunnelMachine

var _start: Vector2i = Vector2i()
var _end: Vector2i = Vector2i()
var _speed: float = 0.1
var _tunnel_progress: float = 0
var _path:Array[Vector2i]
var _path_length: float = 0

signal excavation_finished()

func _ready() -> void:
	connect("excavation_finished", _fade_out)

func _process(delta: float) -> void:
	_move_tunnel_machine(delta)

func setup(start: Vector2i, end: Vector2i, speed: float = 0.1) -> void:
	set_start_and_end(start, end)
	set_speed(speed)
	_path = PathGenerator.generate_path_to(_start, _end)
	create_route()

func set_start(start: Vector2i) -> void:
	_start = start
	position = Vector3(0.0 + 0.5, 1, 0.0)

func set_end(end: Vector2i) -> void:
	_end = end

func set_start_and_end(start: Vector2i, end: Vector2i) -> void:
	set_start(start)
	set_end(end)

func set_speed(speed: float) -> void:
	_speed = speed

func excavate_at_position (pos: Vector2i = Vector2i(), size: Vector2i = Vector2i.ONE) -> void:
	GridLevel.remove_tiles(pos, size)
	#GridLevel._spawn_floor(pos, size)

func create_route() -> void:
	var curve_inst = Curve3D.new()
	# remove the last two tiles from the path
	_path.remove_at(_path.size() - 1)
	for tile in _path:
		curve_inst.add_point(Vector3(tile.x, 0, tile.y + 0.5))
	_path_3d.curve = curve_inst
	_path_length = _path_3d.curve.get_baked_length()

func excavate_path():
	for tile in _path:
		# move the progress along the path 1/length of the path
		#_tunnel_progress += (1.0 / _path.size())
		excavate_at_position(tile, Vector2i.ONE)
		await get_tree().create_timer(_speed).timeout
	emit_signal("excavation_finished")

func _move_tunnel_machine(delta: float) -> void:
	# move slightly every frame in less than the _speed time to the next tile
	if _tunnel_progress >= 1:
		_path_follow_3d.progress_ratio = 1
		return
	else:
		_tunnel_progress += delta / _speed / _path_length *0.95
		_path_follow_3d.progress_ratio = _tunnel_progress

func _fade_out() -> void:
	# fade out mesh after 2 secs
	await get_tree().create_timer(2.0).timeout
	queue_free()
