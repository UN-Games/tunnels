extends Node3D
class_name Spawner

@export var enemy: PackedScene = null

# spawn the amount of enemies at the rate.

@onready var _state_chart: StateChart = %StateChart
@onready var _anim_player: AnimationPlayer = %AnimPlayer
@onready var _mesh: MeshInstance3D = %spawner

func _ready() -> void:
	pass

func set_pos(pos: Vector3) -> void:
	_mesh.position = pos

func spawn_enemies(target: Vector2i, amount: int, rate: float) -> void:
	# play the emerge animation.
	for i in range(amount):
		var enemy_inst: Enemy = enemy.instantiate()
		get_parent().add_child(enemy_inst)
		enemy_inst.setup(Vector2i(floori(global_position.x), floori(global_position.z)), target)
		await get_tree().create_timer(rate).timeout
		# if is the last enemy, play the despawn animation.
		if i == amount - 1:
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
