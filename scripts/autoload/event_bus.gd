extends Node

signal entity_selected(entity: Node)
signal entity_deselected()
signal entity_placed(entity: Node, cell: Vector2i)
signal build_mode_changed(active: bool, entity_id: String)
signal game_saved(path: String)
signal game_loaded(path: String)
signal cell_hovered(cell: Vector2i)
