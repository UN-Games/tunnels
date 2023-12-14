extends Node3D

@onready var gridMap: GridMap = $GridMap

func _ready():
	# Set the grid map to be 20x20 centered at the origin
	_spawn_floor(Vector2(), 100)
	_spawn_dungeon(Vector2(), 80)

	# connect the excavation request signal to the _excavate function
	Events.connect("excavation_requested", _excavate_to_position)
	Events.connect("explosion_requested", _explode_to_position)

func _spawn_floor (pos: Vector2 = Vector2(), size: int = 1 ,  flr: int = 0, item:int = 6, item2: int = 7) -> void:
	# Spawn a floor of size x size at the given position minus half the size
	# set a random floor tile between item and item2 more probable to be item 66%
	# choose a random rotation int beetween 0, 10, 16 and 22
	var cell_pos: Vector3
	for x in range(size):
		for y in range(size):
			cell_pos = Vector3(x - int (size *0.5) + pos.x, flr, y - int (size * 0.5) + pos.y)
			# if the item is a floor tile (6,7) do nothing
			if gridMap.get_cell_item(cell_pos) == 6 or gridMap.get_cell_item(cell_pos) == 7:
				continue
			if (randi() % 100) < 33:
				gridMap.set_cell_item(
					cell_pos,
					item,
					_randi_y_orientation()
					)
			else:
				gridMap.set_cell_item(
					cell_pos,
					item2,
					_randi_y_orientation())

func _spawn_dungeon (pos: Vector2 = Vector2(), size: int = 1, flr: int = 0, item:int = 5) -> void:
	# Spawn a dungeon of size x size at the given position minus half the size
	var previous_floor:bool = false
	var previous_ceil:bool = false
	for x in range(size):
		for y in range(size):
			# The spawn has a 95% chance of spawning a dungeon tile on the first floor
			# If it spawns a dungeon tile, it has a 5% chance of spawning a dungeon tile on the second floor
			# if it doesnt spawn the next spawn has 80% chance of spawning a dungeon tile on the first floor
			var prob = 99
			if previous_floor:
				prob = 85
				# choose a random position near x,y (x-1, x+1, y-1, y+1) and spawn a floor tile
				var rand_x = randi() % 3 - 1
				var rand_y = randi() % 3 - 1
				_spawn_floor(Vector2(x - int (size *0.5) + pos.x + rand_x, y - int (size * 0.5) + pos.y + rand_y), 1, flr, 6, 7)
			if (randi() % 100) < prob:
				previous_floor = false
				gridMap.set_cell_item(Vector3(x - int (size *0.5) + pos.x, flr, y - int (size * 0.5) + pos.y), item)
				var ceil_prob = 1
				if previous_ceil:
					ceil_prob = 10
				if (randi() % 100) < ceil_prob:
					previous_ceil = true
					gridMap.set_cell_item(Vector3(x - int (size *0.5) + pos.x, flr + 1, y - int (size * 0.5) + pos.y), item)
				else:
					previous_ceil = false
			else:
				# spawn a random floor tile
				_spawn_floor(Vector2(x - int (size *0.5) + pos.x, y - int (size * 0.5) + pos.y), 1, flr, 6, 7)
				previous_floor = true
				previous_ceil = false

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

func _remove_tiles (pos: Vector2 = Vector2(), size: int = 1, flr: int = 0, flr_mnt: int = 1) -> void:
	# Remove a floor of size x size at the given position minus half the size
	var cell_pos: Vector3
	for x in range(size):
		for y in range(size):
			for z in range(flr_mnt):
				# get the position of the cell
				cell_pos = Vector3(x - int (size *0.5) + pos.x, flr + z, y - int (size * 0.5) + pos.y)
				# if the item is a floor tile (6,7) do nothing
				if gridMap.get_cell_item(cell_pos) == 6 or gridMap.get_cell_item(cell_pos) == 7:
					continue
				else:
					gridMap.set_cell_item(cell_pos, -1)

func _excavate_to_position (pos: Vector2 = Vector2(), size: int = 1, flr_mnt: int = 1) -> void:
	# excavate the floor at the given position
	_remove_tiles(pos, size, 0, flr_mnt)
	_spawn_floor(pos, size, 0, 6, 7)

func _explode_to_position (pos: Vector2 = Vector2(), size: int = 3) -> void:
	# spend 10 coins to explode, if the player has less than 10 coins do nothing
	print("explode")
	# remove the floor at the given position in a radius of size the first 9 tiles around
	# are removed, then the surrounding 16 have a 66% chance of being removed
	# finally the surrounding 24 have a 33% chance of being removed
	var cell_pos: Vector3
	var cell_pos2: Vector2
	var half_size = int (size * 0.5)
	var boom_prob = 20
	for x in range(size):
		for y in range(size):
			# get the position of the cell
			cell_pos = Vector3(x - int (half_size) + pos.x, 0, y - int (half_size) + pos.y)
			# vector2 version of the cell position
			cell_pos2= Vector2(cell_pos.x, cell_pos.z)
			# if the item is a floor tile (6,7) do nothing
			if gridMap.get_cell_item(cell_pos) == 6 or gridMap.get_cell_item(cell_pos) == 7:
				# increase the probability of spawning a floor tile
				boom_prob += 4
				continue
			# if the cell is in the first 9 surrounding tiles remove it
			if x < (half_size) + 1 and x > (half_size) -1 and y < (half_size) + 1 and y > (half_size) -1:
				_spawn_floor(cell_pos2, 1, 0, 6, 7)
			elif x < (half_size) + 2 and x > (half_size) -2 and y < (half_size) + 2 and y > (half_size) -2:
				_spawn_floor(cell_pos2, 1, 0, 6, 7)
			# if the cell is in the surrounding 16 tiles remove it with a 66% chance
			elif x < (half_size) + 3 and x > (half_size) -3 and y < (half_size) + 3 and y > (half_size) -3:
				if (randi() % 100) < 80 + boom_prob:
					_spawn_floor(cell_pos2, 1, 0, 6, 7)
			# if the cell is in the surrounding 24 tiles remove it with a 33% chance
			elif x < 7 and y < 7:
				if (randi() % 100) < boom_prob:
					_spawn_floor(cell_pos2, 1, 0, 6, 7)
