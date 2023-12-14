extends Node3D
class_name GridLevel

var _grid_map: GridMap

# On init we create the _grid_map
func _init(mesh_lib: MeshLibrary):
	_grid_map = GridMap.new()
	_grid_map.mesh_library = mesh_lib
	# set the scale of tiles to 0.5
	# add the grid map to the scene

func _ready():
	# set the scale of tiles to 0.5
	_grid_map.cell_size = Vector3(1,0.9,1)
	add_child(_grid_map)
	Events.connect("excavation_requested", excavate_to_position)


# func to generate level items
func _generate_level(pos: Vector2i = Vector2i(0, 0), size: Vector2i = Vector2i(0, 0)):
	print("generate level in position: ", pos, " with size: ", size)
	# is grid map mesh library is not set return
	if _grid_map.mesh_library == null:
		print("mesh library not set")
		return
	_spawn_floor(pos, size, 0, 6, 7)
	_spawn_dungeon(pos, size, 0, 5)

# func to spawn the floor
func _spawn_floor (pos: Vector2i = Vector2i(), size: Vector2i = Vector2i() ,  flr: int = 0, item:int = 6, item2: int = 7) -> void:
	# Spawn a floor of size x size at the given position minus half the size
	# set a random floor tile between item and item2 more probable to be item 66%
	# choose a random rotation int beetween 0, 10, 16 and 22
	var cell_pos: Vector2i
	for x in range(size.x):
		for y in range(size.y):
			cell_pos = Vector2i(x - int (size.x *0.5) + pos.x, y - int (size.y * 0.5) + pos.y)
			# if the item is a floor tile (6,7) do nothing
			if get_item(cell_pos) == 6 or get_item(cell_pos) == 7:
				continue
			if (randi() % 100) < 33:
				set_item(cell_pos, item, flr, _randi_y_orientation())
			else:
				set_item(cell_pos, item2, flr, _randi_y_orientation())

func _spawn_dungeon (pos: Vector2i = Vector2i(), size: Vector2i = Vector2i(), flr: int = 0, item:int = 5) -> void:
	# Spawn a dungeon of size x size at the given position minus half the size
	var previous_floor:bool = false
	var previous_ceil:bool = false
	for x in range(size.x):
		for y in range(size.y):
			# The spawn has a 95% chance of spawning a dungeon tile on the first floor
			# If it spawns a dungeon tile, it has a 5% chance of spawning a dungeon tile on the second floor
			# if it doesnt spawn the next spawn has 80% chance of spawning a dungeon tile on the first floor
			var prob = 99
			if previous_floor:
				prob = 85
				# choose a random position near x,y (x-1, x+1, y-1, y+1) and spawn a floor tile
				var rand_x = randi() % 3 - 1
				var rand_y = randi() % 3 - 1
				_spawn_floor(Vector2i(x - int (size.x *0.5) + pos.x + rand_x, y - int (size.y * 0.5) + pos.y + rand_y), Vector2i.ONE, flr, 6, 7)
			if (randi() % 100) < prob:
				previous_floor = false
				set_item(Vector2i(x - int (size.x *0.5) + pos.x, y - int (size.y * 0.5) + pos.y), item, flr)
				var ceil_prob = 1
				if previous_ceil:
					ceil_prob = 10
				if (randi() % 100) < ceil_prob:
					previous_ceil = true
					set_item(Vector2i(x - int (size.x *0.5) + pos.x, y - int (size.y * 0.5) + pos.y), item, flr + 1)
				else:
					previous_ceil = false
			else:
				# spawn a random floor tile
				_spawn_floor(Vector2i(x - int (size.x *0.5) + pos.x, y - int (size.y * 0.5) + pos.y), Vector2i.ONE, flr, 6, 7)
				previous_floor = true
				previous_ceil = false

func _remove_tiles (pos: Vector2i = Vector2i(), size: Vector2i = Vector2i.ONE, flr: int = 0, flr_mnt: int = 1) -> void:
	# Remove a floor of size x size at the given position minus half the size
	var cell_pos: Vector2i
	for x in range(size.x):
		for y in range(size.y):
			for z in range(flr_mnt):
				# get the position of the cell
				cell_pos = Vector2i(x - int (size.x *0.5) + pos.x, y - int (size.y * 0.5) + pos.y)
				# if the item is a floor tile (6,7) do nothing
				if get_item(cell_pos) == 6 or get_item(cell_pos) == 7:
					continue
				else:
					set_item(cell_pos, -1, flr + z)

func excavate_to_position (pos: Vector2i = Vector2i(), size: Vector2i = Vector2i.ONE, flr_mnt: int = 1) -> void:
	# excavate the floor at the given position
	_remove_tiles(pos, size, 0, flr_mnt)
	_spawn_floor(pos, size, 0, 6, 7)

func explode_to_position (pos: Vector2i = Vector2i(), size: int = 3) -> void:
	# spend 10 coins to explode, if the player has less than 10 coins do nothing
	print("explode")
	# remove the floor at the given position in a radius of size the first 9 tiles around
	# are removed, then the surrounding 16 have a 66% chance of being removed
	# finally the surrounding 24 have a 33% chance of being removed
	var cell_pos: Vector2i
	var half_size = int (size * 0.5)
	var boom_prob = 20
	for x in range(size):
		for y in range(size):
			# get the position of the cell
			cell_pos = Vector2i(x - int (half_size) + pos.x, y - int (half_size) + pos.y)
			# if the item is a floor tile (6,7) do nothing
			if get_item(cell_pos) == 6 or get_item(cell_pos) == 7:
				# increase the probability of spawning a floor tile
				boom_prob += 4
				continue
			# if the cell is in the first 9 surrounding tiles remove it
			if x < (half_size) + 1 and x > (half_size) -1 and y < (half_size) + 1 and y > (half_size) -1:
				_spawn_floor(cell_pos, Vector2i.ONE, 0, 6, 7)
			elif x < (half_size) + 2 and x > (half_size) -2 and y < (half_size) + 2 and y > (half_size) -2:
				_spawn_floor(cell_pos, Vector2i.ONE, 0, 6, 7)
			# if the cell is in the surrounding 16 tiles remove it with a 66% chance
			elif x < (half_size) + 3 and x > (half_size) -3 and y < (half_size) + 3 and y > (half_size) -3:
				if (randi() % 100) < 80 + boom_prob:
					_spawn_floor(cell_pos, Vector2i.ONE, 0, 6, 7)
			# if the cell is in the surrounding 24 tiles remove it with a 33% chance
			elif x < 7 and y < 7:
				if (randi() % 100) < boom_prob:
					_spawn_floor(cell_pos, Vector2i.ONE, 0, 6, 7)

# returns the _grid_map
func get_grid_map() -> GridMap:
	return _grid_map

# wrappers for the _grid_map functions
func get_item(pos: Vector2i) -> int:
	return _grid_map.get_cell_item(Vector3i(pos.x, 0, pos.y))

# set new vector3i with the floor at 0
func set_item(pos: Vector2i, item: int, flr:int = 0, orientation: int = 0) -> void:
	_grid_map.set_cell_item(Vector3i(pos.x, flr, pos.y), item, orientation)

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
