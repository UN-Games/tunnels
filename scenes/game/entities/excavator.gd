extends Area3D
class_name Excavator

var _start: Vector2i = Vector2i()
var _end: Vector2i = Vector2i()
var _speed: float = 0.1
var _path:Array[Vector2i]

func setup(start: Vector2i, end: Vector2i, speed: float = 0.1) -> void:
	set_start_and_end(start, end)
	set_speed(speed)
	_path = PathGenerator.generate_path_to(_start, _end)

func set_start(start: Vector2i) -> void:
	_start = start
	position = Vector3(start.x + 0.5, 1, start.y + 0.5)

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

func excavate_path():
	for tile in _path:
		excavate_at_position(tile, Vector2i.ONE)
		await get_tree().create_timer(_speed).timeout
