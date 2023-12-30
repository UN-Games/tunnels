extends Button

@export var activity_icon: Texture2D
@export var activity_draggable: PackedScene
@export var error_mat: BaseMaterial3D
@export var activity_cost: int = 10

const RAYCAST_LENGTH: float = 100

var _draggable: Node3D
var _cam:Camera3D

var _is_dragging: bool = false
var _is_valid_location: bool = false
var _last_valid_location: Vector3

var _drag_alpha: float = 0.5

func _ready() -> void:
	icon = activity_icon
	_draggable = activity_draggable.instantiate()
	add_child(_draggable)
	_draggable.visible = false
	_cam = get_viewport().get_camera_3d()

func _physics_process(delta: float) -> void:
	if !_is_dragging:
		return
	var space_state = _draggable.get_world_3d().direct_space_state
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = _cam.project_ray_origin(mouse_pos)
	var ray_end: Vector3 = ray_origin + _cam.project_ray_normal(mouse_pos) * RAYCAST_LENGTH
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collide_with_areas = true
	var ray_result: Dictionary = space_state.intersect_ray(query)

	if ray_result.size() > 0:
		var col_obj: CollisionObject3D = ray_result.get("collider")
		_on_main_mouse_hit(col_obj)
	else:
		_draggable.visible = false
		_is_valid_location = false
		#print(col_obj.get_groups()[0])

func set_child_mesh_alphas(n:Node):
	for c in n.get_children():
		if c is MeshInstance3D:
			set_mesh_alpha(c)

		if c is Node and c.get_child_count() > 0:
			set_child_mesh_alphas(c)

func set_mesh_alpha(mesh_3d:MeshInstance3D):
	for si in mesh_3d.mesh.get_surface_count():
		mesh_3d.set_surface_override_material(si, mesh_3d.mesh.surface_get_material(si).duplicate())
		mesh_3d.get_surface_override_material(si).transparency = 1
		mesh_3d.get_surface_override_material(si).albedo_color.a = _drag_alpha

func set_child_mesh_error(n:Node):
	for c in n.get_children():
		if c is MeshInstance3D:
			set_mesh_error(c)

		if c is Node and c.get_child_count() > 0:
			set_child_mesh_error(c)

func set_mesh_error(mesh_3d:MeshInstance3D):
	for si in mesh_3d.mesh.get_surface_count():
		mesh_3d.set_surface_override_material(si, error_mat)

func clear_material_overrides(n:Node):
	for c in n.get_children():
		if c is MeshInstance3D:
			clear_material_override(c)

		if c is Node and c.get_child_count() > 0:
			clear_material_overrides(c)

func clear_material_override(mesh_3d:MeshInstance3D):
	for si in mesh_3d.mesh.get_surface_count():
		mesh_3d.set_surface_override_material(si, null)

func _on_main_mouse_hit(tile:CollisionObject3D) -> void:
	_draggable.visible = true

	if tile.get_groups()[0] == "empty":
		set_child_mesh_alphas(_draggable)
		_draggable.global_position = tile.global_position
		_draggable.global_position.y += 1
		_last_valid_location = tile.global_position
		_is_valid_location = true
	else:
		set_child_mesh_error(_draggable)
		_draggable.global_position = Vector3(floori(tile.global_position.x) + 0.5, _last_valid_location.y + 1, floori(tile.global_position.z) + 0.5)
		_is_valid_location = false

func _on_button_down() -> void:
	print("button down")
	# check if there are enough resources to build
	if !EconomyManager.enough_gold(activity_cost):
		print("not enough gold")
		return
	_is_dragging = true
	_is_valid_location = false

func _on_button_up() -> void:
	print("button up")
	_is_dragging = false
	_draggable.visible = false

	if _is_valid_location and EconomyManager.enough_gold(activity_cost):
		EconomyManager.spend_gold(activity_cost)
		var new_object:Structure = activity_draggable.instantiate()
		#get_viewport().add_child(new_object)
		# add child to the GameWorld node
		get_tree().get_root().get_node("GameWorld").add_child(new_object)
		new_object.build_at(Vector2i(floori(_last_valid_location.x), floori(_last_valid_location.z)), 10)
		new_object.global_position = _last_valid_location
