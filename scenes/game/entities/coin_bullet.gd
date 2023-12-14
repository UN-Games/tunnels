extends Node3D


var damage = 1;
var speed = 10;
var target = null;

# move the bullet towards the target until it hits it
func _physics_process(delta):
	if target:
		var dir = (target.global_transform.origin - global_transform.origin).normalized()
		global_transform.origin += dir * speed * delta
		if global_transform.origin.distance_to(target.global_transform.origin) < 1:
			target.damage(damage)
			queue_free()
