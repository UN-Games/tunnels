extends Node3D
class_name Fortress

@export var _bullet: PackedScene = null

@onready var _tower: Node3D = %Tower
@onready var _cannon: Node3D = %Tower/Rotator/Cannon

var _total_life = 10
var _fire_rate = 0.2
var _damage = 1
var _max_range = 1000
var _bullet_speed = 10
var _initial_empty_area: Vector2i = Vector2i(5, 5)

# Preload the bullet model
var target_lock = null

# on ready call the signal of excavate
func _ready():
	pass
	#GridLevel.excavate_path_to(Vector2i(0, 0), Vector2i(15,-5), 10)

func _process(delta):
	if target_lock != null:
		var distance = (target_lock.global_transform.origin - global_transform.origin).length()
		if distance > _max_range:
			target_lock = null
		else:
			look_at(target_lock.global_position, Vector3.UP)
			# lock rotation on the Y axis
			rotation.x = 0
			rotation.z = 0
			if _fire_rate > 0:
				_fire_rate -= delta
			else:
				_fire_rate = 0.2
				# _fire()
	else:
		target_lock = _find_nearest_enemy()

func _fire():
	var bullet = _bullet.instantiate()
	bullet.global_transform.origin = _cannon.global_transform.origin
	bullet._damage = _damage
	bullet.speed = _bullet_speed
	bullet.target = target_lock
	get_parent().add_child(bullet)

# function to detect the nearest enemy and lock target to it
func _find_nearest_enemy():
	var enemies = get_tree().get_nodes_in_group("enemies")
	#print("Enemies: ", enemies.size())
	var nearest_enemy = null
	var nearest_enemy_distance = _max_range
	for enemy in enemies:
		# get the %Area3D node
		var distance = (enemy.position - global_transform.origin).length()
		if distance < nearest_enemy_distance:
			nearest_enemy = enemy
			nearest_enemy_distance = distance
	return nearest_enemy

func deploy():
	GridLevel.remove_tiles(get_pos(), _initial_empty_area)
	Events.emit_signal("tunnel_requested", get_pos(), Vector2i(10, 0))

func get_pos() -> Vector2i:
	return Vector2i(floori(global_position.x), floori(global_position.z))

func set_pos(pos: Vector2i):
	global_position.x = pos.x + 0.5
	global_position.z = pos.y + 0.5
	global_position.y = 1
