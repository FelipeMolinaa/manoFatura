extends Node

class ItemData:
	var id: String
	var display_name: String
	var stackable: bool = true
	var max_stack: int = 64

func get_item(item_id: String) -> ItemData:
	return null

func get_all_items() -> Array[ItemData]:
	return []
