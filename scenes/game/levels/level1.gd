extends Node3D

@onready var gridMap: GridMap = $GridMap

func _ready():
	# Set the grid map to be 20x20 centered at the origin
	_spawn_floor(Vector2(), 100)
	_spawn_dungeon(Vector2(), 80)

	# connect the excavation request signal to the _excavate function
	Events.connect("excavation_requested", _excavate_to_position)

func _spawn_floor (pos: Vector2 = Vector2(), size: int = 1 ,  flr: int = 0, item:int = 6, item2: int = 7) -> void:
	# Spawn a floor of size x size at the given position minus half the size
	# set a random floor tile between item and item2 more probable to be item 66%
	# choose a random rotation int beetween 0, 10, 16 and 22
	for x in range(size):
		for y in range(size):
			if (randi() % 100) < 33:
				gridMap.set_cell_item(
					Vector3(x - int (size *0.5) + pos.x,
					flr, y - int (size * 0.5) + pos.y),
					item,
					_randi_y_orientation()
					)
			else:
				gridMap.set_cell_item(
					Vector3(x - int (size *0.5) + pos.x,
					flr, y - int (size * 0.5) + pos.y),
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
	for x in range(size):
		for y in range(size):
			for z in range(flr_mnt):
				gridMap.set_cell_item(Vector3(x - int (size *0.5) + pos.x, flr + z, y - int (size * 0.5) + pos.y), -1)

func _excavate_to_position (pos: Vector2 = Vector2(), size: int = 1, flr_mnt: int = 1) -> void:
	# excavate the floor at the given position
	_remove_tiles(pos, size, 0, flr_mnt)
	_spawn_floor(pos, size, 0, 6, 7)
	print("excavation requested at position: ", pos)
