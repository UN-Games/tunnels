extends Node3D

@onready var camera: Camera3D = %Elevation/Camera3D
@onready var viewport_width: int = get_viewport().get_size().x
@onready var viewport_height: int = get_viewport().get_size().y
@onready var viewport_min_x_move: int = viewport_width
@onready var viewport_min_y_move: int = viewport_height
# export the pan speed with a slider from 0 to 10 by 0.5 increments
@export_range(0, 10, 0.5) var pan_speed: float = 2.0
@export var allow_pan: bool = true
# movement
@export_range(0, 100, 10) var move_speed: float = 10.0
# zoom
@export_range(0, 1000) var min_zoom: int = 1
@export_range(0, 1000) var max_zoom: int = 90
@export_range(0, 1000, 0.1) var zoom_speed: float = 2.0
@export_range(0, 1, 0.05) var zoom_speed_damp: float = 0.5

# flags

@export var zoom_to_cursor: bool = false

var viewportMousePos = Vector2(0,0)

var _last_mouse_pos: Vector2 = Vector2()
var _last_zoomed_in_pos: Vector2 = Vector2()
var _last_zoomed_out_pos: Vector2 = Vector2()
var _zooming_in: bool = false
var _zooming_out: bool = false
var _is_panning: bool = false
var _zoom_direction: float = 0
var _is_frozen: bool = false


const GROUND_PLANE_0 = Plane(Vector3.UP, Vector3(0, 0, 0))
const GROUND_PLANE_1 = Plane(Vector3.UP, Vector3(0, 1, 0))
const GROUND_PLANE_2 = Plane(Vector3.UP, Vector3(0, 2, 0))
const RAY_LENGTH = 1000

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.connect("camera_freeze_requested", _freeze)
	Events.connect("camera_unfreeze_requested", _unfreeze)
	Events.connect("click_selection_requested", _excavate_on_click)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if _is_frozen:
		return
	_move(delta)
	_zoom(delta)
	_pan(delta)
	# debug position
	#position.x = move_toward(position.x, viewportMousePos.x, viewport_min_x_move * 1)
	# move the camera in negative local z


func _input(event):
	if event is InputEventMouseMotion:
		# debug
		# if the mouse is on the edges minus a margin(25px) move the camera on the x axis
		# if event.position.x < viewport_min_x_move * 0.5:
		# 	# calculate a new x position for the camera to the left minus the width of the viewport
		# 	var difference = (viewport_width - (int(position.x) % viewport_width))
		# 	var new_x_pos = (position.x) - difference
		# 	# Debug new_x_pos
		# 	print(new_x_pos)
		# 	position.x = move_toward(position.x, new_x_pos, difference * 0.001)
		# 	# move the camera left
		# elif event.position.x > get_viewport().get_size().x - (viewport_min_x_move * 0.5):
		# 	# move the camera right
		# 	var difference = (viewport_width - (int(position.x) % viewport_width))
		# 	var new_x_pos = position.x + difference
		# 	# Debug new_x_pos
		# 	print(new_x_pos)
		# 	#position.x += viewport_min_x_move
		# 	position.x = move_toward(position.x, new_x_pos, difference * 1)
		# else:
		# 	viewportMousePos.x = 0
		pass

	if event.is_action_pressed("camera_pan"):
		_is_panning = true
		_last_mouse_pos = get_viewport().get_mouse_position()

	if event.is_action_released("camera_pan"):
		_is_panning = false

	if event.is_action_pressed("camera_zoom_in"):
		_zoom_direction = -1
		_zooming_in = true
		zoom_to_cursor = true

	if event.is_action_pressed("camera_zoom_out"):
		_zoom_direction = 1
		_zooming_out = true
		zoom_to_cursor = true

	if event.is_action_released("camera_zoom_in"):
		# if the mous pos in the viewport is less than half the viewport width set las
		_last_zoomed_in_pos = get_viewport().get_mouse_position()

	if event.is_action_released("camera_zoom_out"):
		_last_zoomed_out_pos = get_viewport().get_mouse_position()

func _move(delta: float) -> void:
	var velocity = Vector3()
	if Input.is_action_pressed("up"):
		velocity -= transform.basis.z
	if Input.is_action_pressed("down"):
		velocity += transform.basis.z
	if Input.is_action_pressed("left"):
		velocity -= transform.basis.x
	if Input.is_action_pressed("right"):
		velocity += transform.basis.x
	velocity = velocity.normalized()
	_translate_location(velocity * move_speed * delta * ((camera.position.z +10) * 0.1))

func _pan(delta: float) -> void:
	if not _is_panning or not allow_pan:
		return
	var displacement = _get_mouse_displacement()
	var velocity = Vector3(displacement.x, 0, displacement.y) * pan_speed * delta * ((camera.position.z +10) * 0.1)
	_translate_location(-velocity)

func _zoom(delta: float) -> void:
	# calculate the new zoom
	var new_zoom = clamp(
		camera.position.z + _zoom_direction * zoom_speed * camera.position.z * delta,
		min_zoom,
		max_zoom
		)
	# save 3d position
	var pointing_at = _get_ground_click_location()
	# zoom, change local position
	camera.position.z = new_zoom

	if zoom_to_cursor and pointing_at != null:
		_realign_camera(pointing_at)
	# stop scrolling
	_zoom_direction *= zoom_speed_damp
	if abs(_zoom_direction) <= 0.001:
		_zoom_direction = 0
		_zooming_in = false
		_zooming_out = false
		zoom_to_cursor = false

func _get_mouse_displacement() -> Vector2:
	var current_mouse_pos = get_viewport().get_mouse_position()
	var displacement = current_mouse_pos - _last_mouse_pos
	_last_mouse_pos = current_mouse_pos
	return displacement

func _get_ground_click_location() -> Vector3:
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_from = camera.project_ray_origin(mouse_pos)
	var ray_to = ray_from + camera.project_ray_normal(mouse_pos) * RAY_LENGTH
	return GROUND_PLANE_1.intersects_ray(ray_from, ray_to)

func _realign_camera(location: Vector3) -> void:
	var new_location:Vector3 = _get_ground_click_location()
	var displacement:Vector3 = new_location - location
	# if the x pos of the last zoomed in pos is less than the half width of the viewport
	# and the x pos of the last zoomed out pos is greater than the half width of the viewport
	if _last_zoomed_in_pos.x < viewport_width * 0.5 and _last_zoomed_out_pos.x > _last_zoomed_in_pos.x and _zooming_out:
		displacement.x *= 0.95
	# if the x pos of the last zoomed in pos is greater than the half width of the viewport
	# and the x pos of the last zoomed out pos is less than the half width of the viewport
	if _last_zoomed_in_pos.x > viewport_width * 0.5 and _last_zoomed_out_pos.x < _last_zoomed_in_pos.x and _zooming_out:
		displacement.x *= 0.95

	# if the y pos of the last zoomed in pos is less than the half height of the viewport
	# and the y pos of the last zoomed out pos is greater than the half height of the viewport
	if _last_zoomed_in_pos.y < viewport_height * 0.5 and _last_zoomed_out_pos.y > _last_zoomed_in_pos.y and _zooming_out:
		displacement.z *= 0.95

	# if the y pos of the last zoomed in pos is greater than the half height of the viewport
	# and the y pos of the last zoomed out pos is less than the half height of the viewport
	if _last_zoomed_in_pos.y > viewport_height * 0.5 and _last_zoomed_out_pos.y < _last_zoomed_in_pos.y and _zooming_out:
		displacement.z *= 0.95

	# multiply with lower values when the displacement is bigger math.pow(0.95, displacement.x) only displacements bigger than 1
	if abs(displacement.x) > 1:
		displacement.x *= pow(0.95, abs(displacement.x))
	if abs(displacement.z) > 1:
		displacement.z *= pow(0.95, abs(displacement.z))

	_translate_location(-displacement)

func _translate_location(vec: Vector3) -> void:
	position += vec
	Events.emit_signal("camera_moved", position)

func _freeze() -> void:
	_is_frozen = true

func _unfreeze() -> void:
	_is_frozen = false

# func print where th click location is
func _excavate_on_click(ability:int = 0) -> void:
	var ground_point = _get_ground_click_location()
	# TODO: check if the click hit a tile using the 3 planes

	# convert the 3d point to a new vector2d point omiting the y axis
	ground_point = Vector2(floori(ground_point.x), floori(ground_point.z))
	# if the ability 1 is active
	match ability:
		1:
			Events.emit_signal("explosion_requested", ground_point, 7)
		2:
			# TODO: change hte ability to build a wall
			Events.emit_signal("explosion_requested", ground_point, 2)
		3:
			# TODO: change hte ability to build a tower
			Events.emit_signal("explosion_requested", ground_point, 3)
		_:
			Events.emit_signal("excavation_requested", ground_point)
