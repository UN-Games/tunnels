extends Area3D

var _pos: Vector2i
var _radius: Vector2i

func setup(pos: Vector2i, radius: Vector2i):
	_pos = pos
	_radius = radius
	position = Vector3(pos.x + 0.5, 1, pos.y + 0.5)

func reveal():
	var revealed:Array[Vector2i] = GridLevel.reveal_to_position(_pos, _radius)
	# spawn a sphere at each revealed tile
	for cell_pos in revealed:
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = SphereMesh.new()
		# add to the world
		print("Spawn sphere at: ", cell_pos)
		get_parent().add_child(mesh_instance)
		mesh_instance.scale = Vector3(0.5, 0.5, 0.5)
		mesh_instance.position = Vector3(cell_pos.x + 0.5, 1.5, cell_pos.y + 0.5)
		mesh_instance.material_override = load("res://assets/materials/red.tres")
		#await get_tree().create_timer(1.0).timeout
		#mesh_instance.queue_free()
	# remove and fade out the
