extends Structure
class_name Tower

@export var projectile_type: PackedScene = null

@export_range(1, 10) var _max_range: int = 4
@export_range(1,100) var _fire_rate: int = 10
@export var _initial_empty_area: Vector2i = Vector2i(1, 1)

@onready var _tower: Node3D = %Tower
@onready var _cannon: Node3D = %Tower/Cannon

@onready var _patrol_area: Area3D = %PatrolArea
@onready var _area_shape: CollisionShape3D = %PatrolArea/CollisionShape3D
@onready var _state_chart: StateChart = %StateChart

var _current_enemy:Node3D = null
var _last_fire_time: int = 0
var _enemies_in_range:Array[Node3D] = []
var _acquire_slerp_progress:float = 0

func _process(delta: float) -> void:
	pass

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
	# print the comparation between the current basis and the target basis on the X and Y axis
	_tower.basis = _tower.basis.slerp(target_basis, _acquire_slerp_progress)
	_acquire_slerp_progress += delta * 0.1
	# check if the progress is over 1 or the tower basis is close enough to the target basis
	if _acquire_slerp_progress > 1 or _tower.basis.tdotx(target_basis.x) > 0.99 or _tower.basis.tdoty(target_basis.y) > 0.99:
		_state_chart.send_event("to_attacking")

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
	_acquire_slerp_progress = 0

func _on_acquiring_state_physics_processing(delta:float) -> void:
	if _current_enemy != null and _enemies_in_range.has(_current_enemy):
		_rotate_towards_target(_current_enemy, delta)
	else:
		_state_chart.send_event("to_patrolling")

func _on_attacking_state_entered() -> void:
	_last_fire_time = 0

func _on_attacking_state_physics_processing(delta:float) -> void:
	if _current_enemy != null and _enemies_in_range.has(_current_enemy):
		_tower.look_at(Vector3(_current_enemy.global_position.x, _tower.global_position.y, _current_enemy.global_position.z), Vector3.UP)
		_maybe_fire()
	else:
		_state_chart.send_event("to_patrolling")

func _maybe_fire() -> void:
	if Time.get_ticks_msec() > _last_fire_time + floori((10000 / _fire_rate)):
		var projectile:Projectile = projectile_type.instantiate()
		# set rotation to the tower's rotation
		projectile.global_transform.basis = _tower.global_transform.basis
		projectile.starting_position = _cannon.global_position
		projectile.target = _current_enemy
		get_tree().root.add_child(projectile)
		_last_fire_time = Time.get_ticks_msec()
