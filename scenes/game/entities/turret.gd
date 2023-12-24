extends Area3D

@onready var tile_collision: CollisionShape3D = %TileCollision
@onready var _tower: Node3D = %TurretFixedScale

var _life: int = 10
var _max_range: int = 5
var _fire_rate: float = 1.0

var _target_lock = null

func setup(pos: Vector2i, life: int = 10, max_range: int = 5, rate: float = 1) -> void:
	print("Tower setup")
	position = Vector3(pos.x + 0.5, 0.5, pos.y + 0.5)
	_life = life
	_max_range = max_range
	_fire_rate = rate
	# activate the tile collision
	tile_collision.disabled = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _process(delta: float) -> void:
	if tile_collision.disabled:
		# rotate slowly around the Y axis
		return
	if _target_lock != null:
		var distance = (_target_lock.global_transform.origin - global_transform.origin).length()
		if distance > _max_range:
			_target_lock = null
		else:
			_tower.look_at(_target_lock.global_position, Vector3.UP)
			# lock rotation on the Y axis
			_tower.rotation.x = 0
			_tower.rotation.z = 0
			if _fire_rate > 0:
				_fire_rate -= delta
			else:
				_fire_rate = 0.2
				# _fire()
	else:
		_tower.rotate_y(delta)
		_target_lock = _find_nearest_enemy()

func _find_nearest_enemy():
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest_enemy = null
	var nearest_enemy_distance = _max_range
	for enemy in enemies:
		# get the %Area3D node
		var distance = (enemy.global_position - global_transform.origin).length()
		if distance < nearest_enemy_distance:
			nearest_enemy = enemy
			nearest_enemy_distance = distance
	return nearest_enemy
