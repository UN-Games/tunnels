extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Move the node 1 unit per second. with awsd


func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * 0.1))
		rotate_x(deg2rad(-event.relative.y * 0.1))
		#rotate_y(deg2rad(-event.relative.x * 0.1))
		#rotate_x(deg2rad(-event.relative.y * 0.1))
		#rotate_y(deg2rad(-event.relative.x * 0.1))
		#rotate_x(deg2rad(-event.relative.y * 0.1))
		#rotate_y(deg2rad(-event.relative.x * 0.1))
		#rotate_x(deg2rad(-event.relative.y * 0.1))
		#rotate_y(deg2rad(-event.relative.x * 0.1))
		#rotate_x(deg2rad(-event.relative.y * 0.1))
		#rotate_y(deg2rad(-event.relative.x * 0.1))
		#rotate_x(deg2rad(-event.relative.y * 0.1))
		#rotate_y(deg2rad(-event.relative.x * 0.1))
		#rotate_x(deg2rad(-event.relative.y * 0.1))
		#rotate_y(deg2rad(-event.relative.x * 0.1))
		#rotate_x(deg2rad(-event.relative.y * 0.1))
		#rotate_y(deg2rad(-event.relative.x * 0.1))
		#rotate_x(deg2rad(-event.relative.y * 0.1))

	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			# Get the mouse position from the event.
			var mouse_pos = event.position
			# Get the mouse position relative to the viewport.
			var viewport = get_viewport()
			var mouse_pos_rel = mouse_pos - viewport.get_mouse_position()
			# Get the ray from the camera to the mouse position.
			var ray_origin = camera.project_ray_origin(mouse_pos_rel)
			var ray_dir = camera.project_ray_normal(mouse_pos_rel)
			var ray_length = 1000
			var ray_end = ray_origin + ray_dir * ray_length
			# Create a PhysicsDirectSpaceState object.
			var space_state = get_world().direct_space_state
			# Perform the raycast
