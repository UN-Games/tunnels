extends Node3D
class_name Spawner

@export var basic_enemy: PackedScene = null

# spawn the amount of enemies at the rate.

@onready var _state_chart: StateChart = %StateChart
@onready var _anim_player: AnimationPlayer = %AnimPlayer
@onready var _mesh: MeshInstance3D = %spawner

func _ready() -> void:
	print(_state_chart.editor_description)

func set_pos(pos: Vector3) -> void:
	_mesh.position = pos

func spawn_enemies(curve3D: Curve3D, amount: int, rate: float) -> void:
	# play the emerge animation.
	for i in range(amount):
		var path_raw: Path3D = Path3D.new()
		path_raw.curve = curve3D
		# create enemy
		var enemy = basic_enemy.instantiate()
		enemy.set_path(path_raw)
		add_child(enemy)
		# add to the scene.
		await get_tree().create_timer(rate).timeout

func _on_emerge_state_entered() -> void:
	_anim_player.play("Esconder acción]_001")
	await _anim_player.animation_finished
	_state_chart.send_event("to_spawning")

func _on_spawning_state_entered() -> void:
	_anim_player.play("Esconder acción]")
