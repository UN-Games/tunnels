extends Node

signal camera_moved(new_location)
signal camera_jump_requested(location, duration)
signal camera_freeze_requested()
signal camera_unfreeze_requested()

# excavation signals
signal excavation_requested(position, size, flr_mnt)
