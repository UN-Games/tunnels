extends Node

var gold: int = 0

func set_gold(amount: int) -> void:
    gold = amount

func get_gold() -> int:
    return gold

func spend_gold(amount: int) -> bool:
    if gold >= amount:
        gold -= amount
        return true
    return false

func enough_gold(amount: int) -> bool:
    return gold >= amount
