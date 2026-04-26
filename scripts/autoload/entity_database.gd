extends Node

class EntityData:
	var id: String
	var display_name: String
	var footprint: Vector2i = Vector2i.ONE
	var scene_path: String
	var cost: Dictionary = {}

func get_entity(entity_id: String) -> EntityData:
	return null

func get_all_entities() -> Array[EntityData]:
	return []
