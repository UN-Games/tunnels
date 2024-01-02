extends Area3D
class_name Projectile

@export var projectile_settings: ProjectileSettings

var starting_position:Vector3
var target:Node3D

var lerp_pos:float = 0
var last_target_pos:Vector3

func _ready():
	global_position = starting_position
	last_target_pos = target.global_position
	lerp_pos = 0

func _process(delta):
	if lerp_pos >= 1:
		queue_free()
		return
	if target != null:
		global_position = starting_position.lerp(target.global_position, lerp_pos)
		last_target_pos = target.global_position

	elif target == null:
		global_position = starting_position.lerp(last_target_pos, lerp_pos)

	lerp_pos += delta * projectile_settings.speed
