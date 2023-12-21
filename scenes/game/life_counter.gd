extends Label

func _ready() -> void:
	Events.connect("lifes_changed", _on_lifes_changed)

func _on_lifes_changed(lifes: int) -> void:
	text = str("Lifes: ", lifes, "/10")
