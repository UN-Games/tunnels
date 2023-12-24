extends Area3D
class_name Spawner

@export var enemy: PackedScene = null

# spawn the amount of enemies at the rate.

@onready var _state_chart: StateChart = %StateChart
@onready var _anim_player: AnimationPlayer = %AnimPlayer
@onready var _mesh: MeshInstance3D = %spawner

var _target: Vector2i = Vector2i(0,0)
var _amount: int = 0
var _rate: float = 0.0

func _ready() -> void:
	pass

func setup(pos: Vector2i, target: Vector2i, amount: int, rate: float) -> void:
	position = Vector3(pos.x + 0.5, 0.5, pos.y + 0.5)
	_target = target
	_amount = amount
	_rate = rate
	# remove the floor from the grid.
	GridLevel.explode_to_position(Vector2i(floori(global_position.x), floori(global_position.z)), Vector2i(3,3))
	#GridLevel.place_item(pos)

func set_pos(pos: Vector3) -> void:
	_mesh.position = pos

func spawn_enemies() -> void:
	for i in _amount:
		var enemy_inst: Enemy = enemy.instantiate()
		get_parent().add_child(enemy_inst)
		enemy_inst.setup(Vector2i(floori(global_position.x), floori(global_position.z)), _target)
		await get_tree().create_timer(_rate).timeout
		# if is the last enemy, play the despawn animation.
	_state_chart.send_event("to_despawning")

func _on_emerge_state_entered() -> void:
	_anim_player.play("emerge")
	await _anim_player.animation_finished
	_state_chart.send_event("to_spawning")

func _on_spawning_state_entered() -> void:
	_anim_player.play("spawn")

func _on_despawning_state_entered() -> void:
	_anim_player.play("despawn")
	await _anim_player.animation_finished
	queue_free()
