extends Node

signal camera_moved(new_location)
signal camera_jump_requested(location, duration)
signal camera_freeze_requested()
signal camera_unfreeze_requested()

# excavation signals
#signal click_selection_requested(position)
signal excavation_requested(position, size, flr_mnt)
signal path_excavation_requested(from, to)
signal explosion_requested(position, size)

# game signals
# get coins
signal coin_collected(amount)
