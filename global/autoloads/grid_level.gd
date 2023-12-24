extends Node3D

@export var empty: PackedScene = null
@export var mines: PackedScene = null

var is_bugged:bool = false # Debug

var _grid_map: GridMap
var _walkable_bm:BitMap = BitMap.new()
var _mines_bm:BitMap = BitMap.new()
var _empty_dict:Dictionary = {}
var _size: Vector2i

func _ready():
	# set the scale of tiles to 0.5
	_create_grid_map(Vector3(1, 0.9, 1))

# func to generate level items
func generate_level(mesh_lib:MeshLibrary, pos: Vector2i = Vector2i(0, 0), size: Vector2i = Vector2i(0, 0)) -> void:
	_size = size
	_grid_map.mesh_library = mesh_lib
	#_spawn_walkable()
	_spawn_dungeon(pos, 0, 1)
	_empty_dict.clear()
	_walkable_bm.create(_size)
	_mines_bm.create(_size)

func _create_grid_map (cell_size: Vector3 = Vector3(1, 1, 1)) -> void:
	if _grid_map != null:
		_grid_map.clear()
	_grid_map = GridMap.new()
	_grid_map.cell_size = cell_size
	add_child(_grid_map)

func spawn_mines (prob: int = 10) -> void:
	for x in range(_size.x):
		for y in range(_size.y):
			if (randi() % 100) < prob:
				# if there is no floor tile at the position spawn a mine
				if get_item(x, y) != 0:
					_mines_bm.set_bit(x, y, true)

func _spawn_floor (x_pos: int, y_pos: int, radius: Vector2i = Vector2i() ,  flr: int = 0, item:int = 0, item2: int = 0) -> void:
	for x in range(radius.x):
		for y in range(radius.y):
			# if the item is a floor tile (0) do nothing
			if get_item(x + x_pos, y + y_pos) == 0:
				continue
			if (randi() % 100) < 33:
				set_item(x + x_pos, y + y_pos, item, flr, _randi_y_orientation())
			else:
				set_item(x + x_pos, y + y_pos, item2, flr, _randi_y_orientation())

func _spawn_dungeon (pos: Vector2i = Vector2i(), flr: int = 0, item:int = 1) -> void:
	var previous_floor:bool = false
	var previous_ceil:bool = false
	for x in range(_size.x):
		for y in range(_size.y):
			var prob = 100
			if previous_floor:
				prob = 85
				# choose a random position near x,y (x-1, x+1, y-1, y+1) and spawn a floor tile
				var rand_x = randi() % 3 - 1
				var rand_y = randi() % 3 - 1
				_spawn_floor(x + pos.x + rand_x, y  + pos.y + rand_y, Vector2i.ONE, flr)
			if (randi() % 100) < prob:
				previous_floor = false
				set_item(x  + pos.x, y + pos.y, item, flr)
				var ceil_prob = 0
				if previous_ceil:
					ceil_prob = 10
				if (randi() % 100) < ceil_prob:
					previous_ceil = true
					set_item(x + pos.x, y + pos.y, item, flr + 1)
				else:
					previous_ceil = false
			else:
				_spawn_floor(x + pos.x, y + pos.y, Vector2i.ONE, flr)
				previous_floor = true
				previous_ceil = false

func remove_tiles (pos: Vector2i, radius: Vector2i = Vector2i.ONE, flr: int = 0, flr_mnt: int = 1) -> void:
	# Remove a floor of size x size at the given position minus half the size
	for x in radius.x:
		for y in radius.y:
			for z in flr_mnt:
				if get_item(x + pos.x - floori(radius.x * 0.5), y + pos.y - floori(radius.y * 0.5)) == 0:
					continue
				else:
					if z == 0:
						set_item(x + pos.x - floori(radius.x * 0.5), y + pos.y - floori(radius.y * 0.5), 0, flr + z)
					else:
						set_item(x + pos.x - floori(radius.x * 0.5), y + pos.y - floori(radius.y * 0.5), -1, flr + z)

func explode_to_position (pos: Vector2i, radius: Vector2i = Vector2i.ONE) -> void:
	# TODO: Move the explosion logic to the bomb class
	var half_size: Vector2i = Vector2i(floori(radius.x * 0.5), floori(radius.y * 0.5))
	var boom_prob = 20
	var cell_pos: Vector2i = Vector2i()
	var rad_pos: Vector2i = Vector2i()
	#remove_tiles(pos, radius)
	for x in radius.x:
		for y in radius.y:
			rad_pos = Vector2i(x - half_size.x, y - half_size.y)
			cell_pos = rad_pos + pos
			if get_item(cell_pos.x, cell_pos.y) == 0:
				# increase the probability of spawning a floor tile
				boom_prob += 4
				continue
			# if the cell is in the first 9 surrounding tiles remove it
			if abs(rad_pos.x) < 1 and abs(rad_pos.y) < 1:
				remove_tiles(cell_pos, Vector2i.ONE)
			elif abs(rad_pos.x) < 2 and abs(rad_pos.y) < 2:
				remove_tiles(cell_pos, Vector2i.ONE)
			# if the cell is in the surrounding 16 tiles remove it with a 66% chance
			elif abs(rad_pos.x) < 3 and abs(rad_pos.y) < 3:
				if (randi() % 100) < 60 + boom_prob:
					remove_tiles(cell_pos, Vector2i.ONE)
			# if the cell is in the surrounding 24 tiles remove it with a 33% chance
			#elif x < 7 and y < 7:
			#	if (randi() % 100) < boom_prob:
			#		_spawn_floor(x_pos, y_pos, Vector2i.ONE, 0)

func reveal_to_position (pos: Vector2i, radius: Vector2i = Vector2i.ONE) -> Array[Vector2i]:

	var half_size: Vector2i = Vector2i(floori(radius.x * 0.5), floori(radius.y * 0.5))
	var cell_pos: Vector2i = Vector2i()
	var rad_pos: Vector2i = Vector2i()
	var revealed:Array[Vector2i] = []
	#reveal the mine tiles around the position
	for x in radius.x:
		for y in radius.y:
			rad_pos = Vector2i(x - half_size.x, y - half_size.y)
			cell_pos = rad_pos + pos
			# if the tile is a wall tile (not walkable) and there is a mine at the position
			if !_walkable_bm.get_bit(cell_pos.x, cell_pos.y) and _mines_bm.get_bit(cell_pos.x, cell_pos.y):
				revealed.append(cell_pos)
	# delete the reve
	return revealed

func is_tile_empty (pos: Vector2i) -> bool:
	return _walkable_bm.get_bit(pos.x, pos.y)

func get_grid_map() -> GridMap:
	return _grid_map

func get_item(x_pos: int, y_pos) -> int:
	return _grid_map.get_cell_item(Vector3i(x_pos, 0, y_pos))

func set_item(x_pos: int, y_pos, item: int, flr:int = 0, orientation: int = 0) -> void:
	if item == 0:
		_walkable_bm.set_bit(x_pos, y_pos, true)
		if !_empty_dict.has(Vector2i(x_pos, y_pos)):
			var empty_tile = empty.instantiate()
			_empty_dict[Vector2i(x_pos, y_pos)] = empty_tile
			add_child(empty_tile)
			empty_tile.position = Vector3(x_pos + 0.5, flr + 0.5, y_pos + 0.5)

		if _mines_bm.get_bit(x_pos, y_pos):
			# spawn a mine
			var mine = mines.instantiate()
			add_child(mine)
			mine.position = Vector3(x_pos + 0.5, flr + 0.5, y_pos + 0.5)

	else:
		_walkable_bm.set_bit(x_pos, y_pos, false)
		# remove the floor tile from the dictionary
		if _empty_dict.has(Vector2i(x_pos, y_pos)):
			_empty_dict[Vector2i(x_pos, y_pos)].queue_free()
			_empty_dict.erase(Vector2i(x_pos, y_pos))

	_grid_map.set_cell_item(Vector3i(x_pos, flr, y_pos), item, orientation)

# items random rotation helpers
func _randi_y_orientation () -> int:
	# Return a random y orientation
	var y_orientation = [0, 10, 16, 22]
	return y_orientation[randi() % 4]

func _randi_x_orientation () -> int:
	# Return a random x orientation
	var x_orientation = [0, 4, 8, 12]
	return x_orientation[randi() % 4]

func _randi_z_orientation () -> int:
	# Return a random z orientation
	var z_orientation = [0, 1, 2, 3]
	return z_orientation[randi() % 4]

func get_obstacles_in_region(pos: Vector2i, size: Vector2i) -> Array[Vector2i]:

	var obstacles:Array[Vector2i] = []

	for i in size.x:
		for j in size.y:
			if !_walkable_bm.get_bit(i + pos.x, j + pos.y):
				obstacles.append(Vector2i(i + pos.x, j + pos.y))
				# spawn debug cube
				#if is_bugged:
				#	var mesh_instance = MeshInstance3D.new()
				#	mesh_instance.mesh = BoxMesh.new()
				#	add_child(mesh_instance)
				#	mesh_instance.scale = Vector3(0.5, 0.5, 0.5)
				#	mesh_instance.position = Vector3(i + pos.x + 0.5, 1.5, j + pos.y + 0.5)

			#if !_walkable_grid[i + pos.x][j + pos.y]:
				#obstacles.append(Vector2i(i + pos.x, j + pos.y))
	return obstacles

func spawn_mine(pos: Vector2i) -> void:
	_mines_bm.set_bit(pos.x, pos.y, true)
	set_item(pos.x, pos.y, 0, 0, 0)
	var mine = mines.instantiate()
	mine.position = Vector3(pos.x + 0.5, 0.5, pos.y + 0.5)
	add_child(mine)
