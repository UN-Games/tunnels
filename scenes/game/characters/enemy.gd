extends Node3D
class_name Enemy

@onready var _character: Area3D = %Path3D/PathFollow3D/Character
@onready var _path_3d: Path3D = %Path3D
@onready var _path_follow_3d: PathFollow3D = %Path3D/PathFollow3D
@onready var _anim_player: AnimationPlayer = %Path3D/PathFollow3D/Character/AnimPlayer
@onready var _state_chart: StateChart = %StateChart

@export var _speed:int = 2

var astar_grid: AStarGrid2D = null
var _enemy_progress: float = 0
var _start: Vector2i = Vector2i(0, 0)
var _target: Vector2i = Vector2i(0, 0)

func _ready() -> void:
	#_character.hide()
	pass

func setup(start: Vector2i, target: Vector2i) -> void:
	_start = start
	_target = target
	_character.position = Vector3(start.x + 0.5, 0.5, start.y + 0.5)

func set_astar_grid() -> void:
	astar_grid = AStarGrid2D.new()

	astar_grid.region = Rect2i(min(_target.x, _start.x) - 1,
						min(_target.y, _start.y) - 1,
						abs(_target.x - _start.x) + 2,
						abs(_target.y - _start.y) + 2)
	astar_grid.cell_size = Vector2(1, 1)

	astar_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar_grid.update()

	var solids = GridLevel.get_obstacles()

	for solid in solids:
		astar_grid.set_point_solid(solid, true)

	# move the start point randomly around the 8 points around the start point
	var start_points = [Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1), Vector2i(-1, -1), Vector2i(-1, 0), Vector2i(-1, 1)]
	var start_point = start_points[randi() % 8]
	var random_out = _start + start_point

	var path = astar_grid.get_point_path(random_out, _target)
	# remove the last point because it is the target
	path.remove_at(path.size() - 1)
	# add the start point to the path
	path.insert(0, _start)

	var curve_inst = Curve3D.new()
	for point in path:
		curve_inst.add_point(Vector3(point.x + 0.5, 0, point.y + 0.5))
	_path_3d.curve = curve_inst

func _on_spawning_state_entered() -> void:
	add_to_group("enemies")
	set_astar_grid()

	_anim_player.play("spawn")
	await _anim_player.animation_finished
	_state_chart.send_event("to_travelling")

func _on_travelling_state_entered() -> void:
	# play the sprint animation with blend of 1 seg and loop animation
	_anim_player.play("sprint")

func _on_travelling_state_processing(delta: float) -> void:
	_enemy_progress += delta * _speed
	_path_follow_3d.progress = _enemy_progress
	_character.position = Vector3( 0, 0.5, 0)

	if _enemy_progress >= _path_3d.curve.get_baked_length():
		# attack first then despawn
		_state_chart.send_event("to_attacking")

func _on_attacking_state_entered() -> void:
	# randoom atack between attack-kick-left and attack-kick-right and also between attack-melee-left and attack-melee-right
	var attack_anim = ["attack-kick-left", "attack-kick-right", "attack-melee-left", "attack-melee-right"][randi() % 4]
	_anim_player.play(attack_anim)
	await _anim_player.animation_finished
	Events.emit_signal("enemy_reached_fortress")
	_state_chart.send_event("to_despawning")

func _on_despawning_state_entered() -> void:
	# Deal some damage to the fortress
	_anim_player.play("despawn")
	await _anim_player.animation_finished
	queue_free()
