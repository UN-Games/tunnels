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
@onready var _state_chart: StateChart = %StateChart

var _current_enemy:Node3D = null
var _time = 0
var _can_fire = true
var _enemies_in_range:Array[Node3D] = []
var _current_enemy_targetted:bool = false
var _acquire_slerp_progress:float = 0

func _process(delta: float) -> void:
	pass

		#aim_at_target()
		#if _can_fire:
			#_fire()
		#	return
		#_time += delta
		#if _time >= _fire_rate:
		#	_time = 0
		#	_can_fire = true

func build_at(pos: Vector2i, life: int, offset: Vector2 = Vector2.ZERO)	-> void:
	super(pos, life, offset)

	GridLevel.remove_tiles(get_pos(), _initial_empty_area)

	_patrol_area.monitoring = true
	_area_shape.shape.radius = _max_range

func aim_at_target() -> void:
	var distance = (_current_enemy.global_transform.origin - global_transform.origin).length()
	if distance > _max_range:
		_current_enemy = null
	else:
		# lock rotation on the Y axis
		pass


func _rotate_towards_target(rtarget, delta):
	var target_vector = _tower.global_position.direction_to(Vector3(rtarget.global_position.x, _tower.global_position.y, rtarget.global_position.z))
	var target_basis:Basis = Basis.looking_at(target_vector, Vector3.UP)
	_tower.basis = _tower.basis.slerp(target_basis, _acquire_slerp_progress)
	_acquire_slerp_progress += delta

	if _acquire_slerp_progress > 1:
		_state_chart.send_event("to_attacking")

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
	var nearest_enemy_distance = _max_range +1
	for enemy in _enemies_in_range:
		# get the %Area3D node
		var distance = (enemy.global_position - global_transform.origin).length()
		if distance < nearest_enemy_distance:
			nearest_enemy = enemy
			nearest_enemy_distance = distance
	return nearest_enemy

func _on_patrol_area_area_entered(area:Area3D) -> void:
	_enemies_in_range.append(area)

func _on_patrol_area_area_exited(area:Area3D) -> void:
	_enemies_in_range.erase(area)

func set_patrolling(patrolling: bool):
	%PatrolArea.monitoring = patrolling

func _on_patrolling_state_processing(delta:float) -> void:
	if tile_collision.disabled:
		return
	_tower.rotate_y(delta * 0.1)
	if _enemies_in_range.size() > 0:
		_current_enemy = _find_nearest_enemy()
		_state_chart.send_event("to_acquiring")

func _on_acquiring_state_entered() -> void:
	_current_enemy_targetted = false
	_acquire_slerp_progress = 0

func _on_acquiring_state_physics_processing(delta:float) -> void:
	if _current_enemy != null and _enemies_in_range.has(_current_enemy):
		_rotate_towards_target(_current_enemy, delta)
	else:
		_state_chart.send_event("to_patrolling")

func _on_attacking_state_entered() -> void:
	_current_enemy_targetted = true

func _on_attacking_state_physics_processing(delta:float) -> void:
	if _current_enemy != null and _enemies_in_range.has(_current_enemy) == false:
		_tower.look_at(Vector3(_current_enemy.global_position.x, _tower.global_position.y, _current_enemy.global_position.z), Vector3.UP)
	else:
		_state_chart.send_event("to_patrolling")
