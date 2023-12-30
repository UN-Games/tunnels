extends Structure
class_name Tower

@export var _bullet: PackedScene = null

@export_range(1,100) var _damage: int = 1
@export_range(1, 10) var _max_range: int = 4
@export_range(1,100) var _fire_rate: int = 10
@export_range(1, 100) var _bullet_speed = 10
@export var _initial_empty_area: Vector2i = Vector2i(1, 1)

@onready var _tower: Node3D = %Tower
@onready var _cannon: Node3D = %Tower/Cannon

@onready var _patrol_area: Area3D = %PatrolArea
@onready var _area_shape: CollisionShape3D = %PatrolArea/CollisionShape3D

var _target_lock = null
var _time = 0
var _can_fire = true
var _enemies_in_range:Array[Node3D] = []

func _process(delta: float) -> void:
	if tile_collision.disabled:
		return

	if _target_lock != null:	# TODO: move this to a separate function
		aim_at_target()
		if _can_fire:
			#_fire()
			return
		_time += delta
		if _time >= _fire_rate:
			_time = 0
			_can_fire = true
	else:
		_idle()
		_target_lock = _find_nearest_enemy()

func build_at(pos: Vector2i, life: int, offset: Vector2 = Vector2.ZERO)	-> void:
	super(pos, life, offset)

	GridLevel.remove_tiles(get_pos(), _initial_empty_area)

	_patrol_area.monitoring = true
	_area_shape.shape.radius = _max_range

func aim_at_target() -> void:
	var distance = (_target_lock.global_transform.origin - global_transform.origin).length()
	if distance > _max_range:
		_target_lock = null
	else:
		_tower.look_at(_target_lock.global_position, Vector3.UP)
		# lock rotation on the Y axis
		_tower.rotation.x = 0
		_tower.rotation.z = 0

func _idle() -> void:
	_tower.rotate_y(0.01)

func _fire() -> void:
	_can_fire = false
	var bullet = _bullet.instance()
	bullet.global_transform.origin = _cannon.global_transform.origin
	bullet.global_transform.basis = _cannon.global_transform.basis
	bullet.damage = _damage
	bullet.speed = _bullet_speed
	get_tree().root.add_child(bullet)

func _find_nearest_enemy():
	var nearest_enemy = null
	var nearest_enemy_distance = _max_range
	for enemy in _enemies_in_range:
		# get the %Area3D node
		var distance = (enemy.global_position - global_transform.origin).length()
		if distance < nearest_enemy_distance:
			nearest_enemy = enemy
			nearest_enemy_distance = distance
	return nearest_enemy

func _on_patrol_area_area_entered(area:Area3D) -> void:
	_enemies_in_range.append(area)
	print("Enemies in range: ", _enemies_in_range.size())

func _on_patrol_area_area_exited(area:Area3D) -> void:
	_enemies_in_range.erase(area)
	print("Enemies in range: ", _enemies_in_range.size())

func set_patrolling(patrolling: bool):
	%PatrolArea.monitoring = patrolling
