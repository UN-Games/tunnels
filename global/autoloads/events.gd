extends Node

# camera
signal camera_moved(new_location)
signal camera_jump_requested(location, duration)
signal camera_freeze_requested()
signal camera_unfreeze_requested()

# game signals
signal excavation_requested(location, size)
signal tunnel_requested(start, end)
signal enemy_reached_fortress

# get coins
signal coin_collected(amount)

# UI
signal lifes_changed(lifes)
