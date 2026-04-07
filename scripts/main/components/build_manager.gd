extends Node

const EntityDatabase = preload("res://scripts/data/entity_database.gd")
const InventoryUtils = preload("res://scripts/data/inventory_utils.gd")
const RecipeDatabase = preload("res://scripts/data/recipe_database.gd")

const BUILD_SCENES := {
	"maquina": preload("res://scenes/entities/machine.tscn"),
	"bau": preload("res://scenes/entities/chest.tscn"),
	"fonte_aco": preload("res://scenes/entities/steel_source.tscn"),
	"vendedor": preload("res://scenes/entities/vendor.tscn"),
}

signal building_selected(entity_id: String)
signal entity_placed(entity_id: String, cell: Vector2i)
signal purchase_failed(entity_id: String, cost: int, current_money: int)
signal entity_sold(entity_id: String, value: int)

@export_node_path("Node2D") var grid_overlay_path: NodePath
@export_node_path("Node2D") var entities_container_path: NodePath
@export_node_path("Node") var money_system_path: NodePath

var selected_building_id := ""
var occupied_cells: Array[Vector2i] = []
var _build_mode_enabled := false
var _moving_entity: Node2D
var _moving_entity_restore_position := Vector2.ZERO
var _moving_entity_restore_cells: Array[Vector2i] = []

@onready var grid_overlay: Node2D = get_node(grid_overlay_path) as Node2D
@onready var entities_container: Node2D = get_node(entities_container_path) as Node2D
@onready var money_system: MoneySystem = get_node(money_system_path) as MoneySystem


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
	if not was_moving:
		var purchase_cost: int = int(definition["purchase_cost"])
		if not money_system.spend(purchase_cost):
			purchase_failed.emit(definition["id"], purchase_cost, money_system.money)
			return

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
			var entity_id: String = str(entity.get_meta("entity_id", ""))
			var entity_definition := EntityDatabase.get_entity(entity_id)
			var sell_value := int(entity_definition.get("valorVenda", 0))
			money_system.earn(sell_value)
			entity_sold.emit(entity_id, sell_value)
			entities_container.remove_child(entity)
			entity.queue_free()
	_rebuild_occupied_cells()


func get_entities_state() -> Array[Dictionary]:
	var entities_state: Array[Dictionary] = []
	for child in entities_container.get_children():
		var entity_id: String = str(child.get_meta("entity_id", ""))
		if entity_id.is_empty():
			continue

		var entity_definition := EntityDatabase.get_entity(entity_id)
		var size: Vector2i = entity_definition.get("tamanho", Vector2i.ONE)
		var cell: Vector2i = grid_overlay.get_cell_from_world_position(child.position)
		var state := {
			"entity_id": entity_id,
			"cell": {"x": cell.x, "y": cell.y},
		}
		if child.has_meta("recipe_id"):
			state["recipe_id"] = str(child.get_meta("recipe_id", ""))
		if child.has_meta("inventory_data"):
			var inventory_data: Variant = child.get_meta("inventory_data", {})
			if inventory_data is Dictionary:
				state["inventory"] = InventoryUtils.duplicate_inventory(inventory_data)
		state["size"] = {"x": size.x, "y": size.y}
		entities_state.append(state)
	return entities_state


func load_entities_state(entities_state: Array[Dictionary]) -> void:
	clear_all_entities(false)
	for state in entities_state:
		_spawn_entity_from_state(state)
	_rebuild_occupied_cells()


func clear_all_entities(emit_signals := true) -> void:
	for child in entities_container.get_children():
		entities_container.remove_child(child)
		child.queue_free()
	_rebuild_occupied_cells()
	if emit_signals:
		building_selected.emit(selected_building_id)


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
		"purchase_cost": int(entity_definition.get("valorCompra", 0)),
		"scene": BUILD_SCENES[entity_id],
	}


func _spawn_entity_from_state(state: Dictionary) -> void:
	var entity_id: String = str(state.get("entity_id", ""))
	if entity_id.is_empty() or not BUILD_SCENES.has(entity_id):
		return

	var entity_definition := EntityDatabase.get_entity(entity_id)
	var size: Vector2i = entity_definition.get("tamanho", Vector2i.ONE)
	var cell_data: Dictionary = state.get("cell", {})
	var cell := Vector2i(int(cell_data.get("x", 0)), int(cell_data.get("y", 0)))
	var entity_scene: PackedScene = BUILD_SCENES[entity_id]
	var instance := entity_scene.instantiate() as Node2D
	instance.position = grid_overlay.get_cell_world_position(cell)
	instance.set_meta("entity_id", entity_id)
	instance.set_meta("occupied_cells", _cells_for_area(cell, size))
	if state.has("recipe_id"):
		instance.set_meta("recipe_id", str(state.get("recipe_id", "")))
	if state.has("inventory"):
		var inventory_state: Variant = state.get("inventory", {})
		if inventory_state is Dictionary:
			instance.set_meta("inventory_data", InventoryUtils.duplicate_inventory(inventory_state))
	_apply_entity_defaults(instance, entity_id)
	entities_container.add_child(instance)


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
	var inventory_defaults := _get_default_inventory_for_entity(entity_id)
	if not inventory_defaults.is_empty():
		var default_slot_labels: Array = []
		var raw_slot_labels: Variant = inventory_defaults.get("slot_labels", [])
		if raw_slot_labels is Array:
			default_slot_labels = raw_slot_labels
		var default_max_amount: int = int(inventory_defaults.get("max_amount", -1))
		var forced_slot_count: int = int(inventory_defaults.get("force_slot_count", -1))
		entity.set_meta(
			"inventory_data",
			InventoryUtils.normalize_inventory(
				entity.get_meta("inventory_data", {}),
				default_slot_labels,
				float(inventory_defaults.get("max_weight", -1.0)),
				default_max_amount,
				forced_slot_count
			)
		)

	if entity_id == "maquina":
		var current_recipe_id: String = entity.get_meta("recipe_id", "")
		if current_recipe_id.is_empty():
			current_recipe_id = "parafuso"
			entity.set_meta("recipe_id", current_recipe_id)

		var recipe := RecipeDatabase.get_recipe(current_recipe_id)
		if entity.has_method("set_secondary_label"):
			entity.set_secondary_label(recipe.get("id", current_recipe_id).capitalize())


func _get_default_inventory_for_entity(entity_id: String) -> Dictionary:
	if entity_id == "maquina":
		return {
			"slot_labels": ["Entrada", "Saida"],
			"max_weight": 25.0,
		}
	if entity_id == "bau":
		return {
			"slot_labels": ["Item"],
			"max_weight": 250.0,
			"max_amount": 1,
			"force_slot_count": 1,
		}
	return {}
