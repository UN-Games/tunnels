extends Tower
class_name Fortress

func build_at(pos: Vector2i, life: int, offset: Vector2 = Vector2.ZERO):
	super(pos, life, offset)
	Events.emit_signal("tunnel_requested", get_pos(), Vector2i(10, 0))
