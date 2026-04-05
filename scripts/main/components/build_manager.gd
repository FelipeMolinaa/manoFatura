extends Node

const EntityDatabase = preload("res://scripts/data/entity_database.gd")
const RecipeDatabase = preload("res://scripts/data/recipe_database.gd")

const BUILD_SCENES := {
	"maquina": preload("res://scenes/entities/machine.tscn"),
	"bau": preload("res://scenes/entities/chest.tscn"),
	"fonte_aco": preload("res://scenes/entities/steel_source.tscn"),
	"vendedor": preload("res://scenes/entities/vendor.tscn"),
}

signal building_selected(entity_id: String)
signal entity_placed(entity_id: String, cell: Vector2i)

@export_node_path("Node2D") var grid_overlay_path: NodePath
@export_node_path("Node2D") var entities_container_path: NodePath

var selected_building_id := ""
var occupied_cells: Array[Vector2i] = []
var _build_mode_enabled := false
var _moving_entity: Node2D
var _moving_entity_restore_position := Vector2.ZERO
var _moving_entity_restore_cells: Array[Vector2i] = []

@onready var grid_overlay: Node2D = get_node(grid_overlay_path) as Node2D
@onready var entities_container: Node2D = get_node(entities_container_path) as Node2D


func _ready() -> void:
	grid_overlay.placement_requested.connect(_on_grid_placement_requested)
	_refresh_grid_build_preview()
	_refresh_grid_occupancy()


func set_build_mode_enabled(enabled: bool) -> void:
	_build_mode_enabled = enabled
	grid_overlay.set("build_mode_enabled", enabled)
	if not enabled:
		cancel_pending_placement()
	_refresh_grid_build_preview()


func select_building(entity_id: String) -> void:
	if _moving_entity != null:
		_restore_moving_entity()
	if selected_building_id == entity_id:
		return
	selected_building_id = entity_id
	_refresh_grid_build_preview()
	building_selected.emit(selected_building_id)


func get_selected_building_id() -> String:
	return selected_building_id


func has_pending_placement() -> bool:
	return not selected_building_id.is_empty()


func cancel_pending_placement() -> void:
	if _moving_entity != null:
		_restore_moving_entity()
	elif selected_building_id.is_empty():
		return

	selected_building_id = ""
	_refresh_grid_build_preview()
	building_selected.emit(selected_building_id)


func begin_move_entity(entity: Node2D) -> void:
	if not is_instance_valid(entity):
		return

	if _moving_entity != null:
		_restore_moving_entity()

	selected_building_id = entity.get_meta("entity_id", "")
	_moving_entity = entity
	_moving_entity_restore_position = entity.position
	_moving_entity_restore_cells = entity.get_meta("occupied_cells", []).duplicate()
	entities_container.remove_child(entity)
	_rebuild_occupied_cells()
	_refresh_grid_build_preview()
	building_selected.emit(selected_building_id)


func _on_grid_placement_requested(cell: Vector2i) -> void:
	if selected_building_id.is_empty():
		return

	var definition := _get_build_definition(selected_building_id)
	var size: Vector2i = definition["size"]

	if not grid_overlay.is_area_free(cell, size):
		return

	var was_moving := _moving_entity != null
	var instance: Node2D
	if was_moving:
		instance = _moving_entity
		_moving_entity = null
		_moving_entity_restore_cells.clear()
	else:
		var entity_scene: PackedScene = definition["scene"]
		instance = entity_scene.instantiate() as Node2D

	instance.position = grid_overlay.get_cell_world_position(cell)
	instance.set_meta("entity_id", definition["id"])
	instance.set_meta("occupied_cells", _cells_for_area(cell, size))
	_apply_entity_defaults(instance, definition["id"])
	entities_container.add_child(instance)

	_rebuild_occupied_cells()
	if was_moving:
		selected_building_id = ""
		_refresh_grid_build_preview()
		building_selected.emit(selected_building_id)
	entity_placed.emit(definition["id"], cell)


func _refresh_grid_build_preview() -> void:
	grid_overlay.set("placement_enabled", _build_mode_enabled and has_pending_placement())
	if not has_pending_placement():
		return

	var definition := _get_build_definition(selected_building_id)
	grid_overlay.set_build_preview(definition["size"], definition["color"])


func _refresh_grid_occupancy() -> void:
	grid_overlay.set_occupied_cells(occupied_cells)


func remove_entities(entities: Array[Node2D]) -> void:
	for entity in entities:
		if is_instance_valid(entity):
			entities_container.remove_child(entity)
			entity.queue_free()
	_rebuild_occupied_cells()


func _unhandled_input(event: InputEvent) -> void:
	if not _build_mode_enabled or not has_pending_placement():
		return

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		cancel_pending_placement()
		get_viewport().set_input_as_handled()


func _get_build_definition(entity_id: String) -> Dictionary:
	var entity_definition := EntityDatabase.get_entity(entity_id)
	return {
		"id": entity_definition["id"],
		"name": entity_definition["nome"],
		"size": entity_definition["tamanho"],
		"color": entity_definition["cor"],
		"scene": BUILD_SCENES[entity_id],
	}


func _rebuild_occupied_cells() -> void:
	occupied_cells.clear()

	for child in entities_container.get_children():
		var child_cells = child.get_meta("occupied_cells", [])
		for cell in child_cells:
			occupied_cells.append(cell)

	_refresh_grid_occupancy()


func _cells_for_area(origin: Vector2i, size: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(size.y):
		for x in range(size.x):
			cells.append(origin + Vector2i(x, y))
	return cells


func _restore_moving_entity() -> void:
	if _moving_entity == null:
		return

	_moving_entity.position = _moving_entity_restore_position
	_moving_entity.set_meta("occupied_cells", _moving_entity_restore_cells.duplicate())
	entities_container.add_child(_moving_entity)
	_moving_entity = null
	_moving_entity_restore_cells.clear()
	_rebuild_occupied_cells()


func _apply_entity_defaults(entity: Node2D, entity_id: String) -> void:
	if entity_id != "maquina":
		return

	var current_recipe_id: String = entity.get_meta("recipe_id", "")
	if current_recipe_id.is_empty():
		current_recipe_id = "parafuso"
		entity.set_meta("recipe_id", current_recipe_id)

	var recipe := RecipeDatabase.get_recipe(current_recipe_id)
	if entity.has_method("set_secondary_label"):
		entity.set_secondary_label(recipe.get("id", current_recipe_id).capitalize())
