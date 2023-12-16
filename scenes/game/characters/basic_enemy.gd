extends Node3D

@onready var _character: Node3D = %Character
@onready var _anim_player: AnimationPlayer = %AnimPlayer
@onready var _state_chart: StateChart = %StateChart


@export var _speed:int = 2

var _path_3d: Path3D
var _path_follow_3d: PathFollow3D
var _enemy_progress:float = 0.0

func _ready() -> void:
	# add to the scene
	# change the character instance parent to the path follow
	# hide the character
	_character.hide()
	_character.reparent(_path_follow_3d, false)
	pass

func set_path(path: Path3D) -> void:
	_path_3d = path
	# create a new follow path child of the _path_3d
	_path_follow_3d = PathFollow3D.new()
	# loop to false
	_path_follow_3d.loop = false
	_path_3d.add_child(_path_follow_3d)
	# add the path instance to the scene
	add_child(_path_3d)

	# progress to 0
	_path_follow_3d.progress_ratio = 0

func _on_spawning_state_entered() -> void:
	# show the character
	# add to group enemies
	add_to_group("enemies")
	_anim_player.play("spawn")
	_character.show()
	await _anim_player.animation_finished
	_state_chart.send_event("to_travelling")

func _on_travelling_state_entered() -> void:
	# play the sprint animation with blend of 1 seg and loop animation
	_anim_player.play("sprint")

func _on_travelling_state_processing(delta: float) -> void:
	_enemy_progress += delta * _speed
	_path_follow_3d.progress = _enemy_progress

	if _enemy_progress >= _path_3d.curve.get_baked_length():
		# attack first then despawn
		_state_chart.send_event("to_attacking")

func _on_attacking_state_entered() -> void:
	# randoom atack between attack-kick-left and attack-kick-right and also between attack-melee-left and attack-melee-right
	var attack_anim = ["attack-kick-left", "attack-kick-right", "attack-melee-left", "attack-melee-right"][randi() % 4]
	_anim_player.play(attack_anim)
	await _anim_player.animation_finished
	_state_chart.send_event("to_despawning")

func _on_despawning_state_entered() -> void:
	# Deal some damage to the fortress

	_anim_player.play("despawn")
	await _anim_player.animation_finished
	queue_free()

func get_character_pos() -> Vector3:
	# return the global position of the character
	return _character.global_transform.origin
