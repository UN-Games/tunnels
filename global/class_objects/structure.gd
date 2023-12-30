extends Node3D
class_name Structure

@export_range(1,100) var _life: int = 10

@onready var tile_collision: CollisionShape3D = %TileCollision

var _offset: Vector2i = Vector2i(0.5,0.5)

func _process(delta: float) -> void:
	if tile_collision.disabled:
		return

func build_at(pos: Vector2i, life: int, offset: Vector2= Vector2.ZERO) -> void:
	position = Vector3(pos.x + offset.x, 0, pos.y + offset.y)
	_life = life
	_offset = offset
	tile_collision.disabled = false
	#$LifeBar.value = _life
	#$LifeBar.max_value = _life

func get_pos() -> Vector2i:
	return Vector2i(floori(global_position.x), floori(global_position.z))

func set_pos(pos: Vector2i):
	global_position.x = pos.x + _offset.x
	global_position.z = pos.y + _offset.y
	global_position.y = 1
