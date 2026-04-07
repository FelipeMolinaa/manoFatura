extends Node2D

const InventoryUtils = preload("res://scripts/data/inventory_utils.gd")
const RecipeDatabase = preload("res://scripts/data/recipe_database.gd")

const TILE_SIZE := 32
const MACHINE_STATE_WAITING := "aguardando"
const MACHINE_STATE_SUPPLIED := "abastecida"
const MACHINE_STATE_PRODUCING := "produzindo"
const MACHINE_STATE_READY := "pronta"
const MACHINE_INPUT_SLOT_LABEL := "Entrada"
const MACHINE_OUTPUT_SLOT_LABEL := "Saida"

@export var entity_name := "Entidade"
@export var entity_size_in_tiles := Vector2i(2, 2)
@export var entity_color := Color("38bdf8")
@export var is_infinite_source := false

var _selection_state := "none"
var _secondary_label := ""
var _simulation_paused := false


func _ready() -> void:
	_ensure_machine_state()
	queue_redraw()


func _process(delta: float) -> void:
	if _simulation_paused:
		return
	if not _is_machine():
		return

	_update_machine_production(delta)


func _draw() -> void:
	var size := Vector2(entity_size_in_tiles * TILE_SIZE)
	var rect := Rect2(Vector2.ZERO, size)
	var fill_color := entity_color
	fill_color.a = 0.9
	var border_color := entity_color.lightened(0.2)
	var label_color := Color("e2e8f0")

	draw_rect(rect, fill_color, true)
	draw_rect(rect, border_color, false, 2.0)
	draw_line(Vector2(0, 0), size, Color(1, 1, 1, 0.12), 1.0)
	draw_line(Vector2(size.x, 0), Vector2(0, size.y), Color(1, 1, 1, 0.12), 1.0)

	if _selection_state != "none":
		var selection_color := Color("38bdf8")
		if _selection_state == "danger":
			selection_color = Color("f97316")
		var selection_fill := selection_color
		selection_fill.a = 0.1
		draw_rect(rect.grow(3.0), selection_fill, true)
		draw_rect(rect.grow(3.0), selection_color, false, 3.0)

	var font := ThemeDB.fallback_font
	if font != null:
		var font_size := 16
		var text_size := font.get_string_size(entity_name, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var text_position := Vector2(
			(size.x - text_size.x) * 0.5,
			(size.y + text_size.y) * 0.5 - 4.0
		)
		draw_string(font, text_position, entity_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, label_color)

		if is_infinite_source:
			draw_string(font, Vector2(10, 20), "INF", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("ecfeff"))

		if not _secondary_label.is_empty():
			draw_string(font, Vector2(10, size.y - 10), _secondary_label, HORIZONTAL_ALIGNMENT_LEFT, size.x - 20, 12, Color("cbd5e1"))


func set_selection_state(value: String) -> void:
	if _selection_state == value:
		return
	_selection_state = value
	queue_redraw()


func set_secondary_label(value: String) -> void:
	if _secondary_label == value:
		return
	_secondary_label = value
	queue_redraw()


func set_simulation_paused(paused: bool) -> void:
	_simulation_paused = paused


func configure_machine_recipe(recipe_id: String) -> void:
	if not _is_machine():
		return
	if RecipeDatabase.get_recipe(recipe_id).is_empty():
		return

	set_meta("recipe_id", recipe_id)
	set_meta("machine_state", MACHINE_STATE_WAITING)
	set_meta("machine_progress_ms", 0.0)
	_refresh_machine_label()


func get_machine_status_text() -> String:
	if not _is_machine():
		return ""

	_ensure_machine_state()
	var state: String = str(get_meta("machine_state", MACHINE_STATE_WAITING))
	if state == MACHINE_STATE_PRODUCING:
		var recipe := RecipeDatabase.get_recipe(str(get_meta("recipe_id", "")))
		var duration_ms := maxf(float(recipe.get("tempoProducao", 1.0)), 1.0)
		var progress_ms := clampf(float(get_meta("machine_progress_ms", 0.0)), 0.0, duration_ms)
		return "%s (%.0f%%)" % [_format_machine_state(state), progress_ms * 100.0 / duration_ms]
	return _format_machine_state(state)


func contains_global_point(world_position: Vector2) -> bool:
	return get_global_bounds().has_point(world_position)


func get_global_bounds() -> Rect2:
	return Rect2(global_position, Vector2(entity_size_in_tiles * TILE_SIZE))


func _update_machine_production(delta: float) -> void:
	_ensure_machine_state()

	var recipe_id: String = str(get_meta("recipe_id", ""))
	var recipe := RecipeDatabase.get_recipe(recipe_id)
	if recipe.is_empty() or not has_meta("inventory_data"):
		return

	var state: String = str(get_meta("machine_state", MACHINE_STATE_WAITING))
	if state == MACHINE_STATE_READY:
		if not _has_recipe_outputs(recipe):
			_set_machine_state(MACHINE_STATE_WAITING)
		return

	if state == MACHINE_STATE_PRODUCING:
		var progress_ms := float(get_meta("machine_progress_ms", 0.0)) + delta * 1000.0
		var duration_ms := maxf(float(recipe.get("tempoProducao", 1.0)), 1.0)
		set_meta("machine_progress_ms", progress_ms)
		if progress_ms >= duration_ms:
			_finish_machine_production(recipe)
		_refresh_machine_label()
		return

	if not _has_recipe_inputs(recipe):
		_set_machine_state(MACHINE_STATE_WAITING)
		return

	if not _can_store_recipe_outputs(recipe):
		_set_machine_state(MACHINE_STATE_SUPPLIED)
		return

	_start_machine_production(recipe)


func _start_machine_production(recipe: Dictionary) -> void:
	var inventory: Dictionary = get_meta("inventory_data", {})
	for raw_entry in recipe.get("entradas", []):
		if raw_entry is not Dictionary:
			continue
		var entry: Dictionary = raw_entry
		InventoryUtils.remove_item_amount_from_slot(
			inventory,
			MACHINE_INPUT_SLOT_LABEL,
			str(entry.get("item", "")),
			_get_recipe_amount(entry)
		)

	set_meta("inventory_data", inventory)
	set_meta("machine_progress_ms", 0.0)
	_set_machine_state(MACHINE_STATE_PRODUCING)


func _finish_machine_production(recipe: Dictionary) -> void:
	var inventory: Dictionary = get_meta("inventory_data", {})
	for raw_entry in recipe.get("saidas", []):
		if raw_entry is not Dictionary:
			continue
		var entry: Dictionary = raw_entry
		InventoryUtils.add_item_amount_to_slot(
			inventory,
			MACHINE_OUTPUT_SLOT_LABEL,
			str(entry.get("item", "")),
			_get_recipe_amount(entry)
		)

	set_meta("inventory_data", inventory)
	set_meta("machine_progress_ms", 0.0)
	_set_machine_state(MACHINE_STATE_READY)


func _has_recipe_inputs(recipe: Dictionary) -> bool:
	var inventory: Dictionary = get_meta("inventory_data", {})
	for raw_entry in recipe.get("entradas", []):
		if raw_entry is not Dictionary:
			continue
		var entry: Dictionary = raw_entry
		var available_amount := InventoryUtils.get_item_amount_in_slot(
			inventory,
			MACHINE_INPUT_SLOT_LABEL,
			str(entry.get("item", ""))
		)
		if available_amount + 0.0001 < _get_recipe_amount(entry):
			return false
	return true


func _can_store_recipe_outputs(recipe: Dictionary) -> bool:
	var inventory: Dictionary = get_meta("inventory_data", {})
	var simulated_inventory: Dictionary = InventoryUtils.duplicate_inventory(inventory)
	for raw_entry in recipe.get("entradas", []):
		if raw_entry is not Dictionary:
			continue
		var entry: Dictionary = raw_entry
		InventoryUtils.remove_item_amount_from_slot(
			simulated_inventory,
			MACHINE_INPUT_SLOT_LABEL,
			str(entry.get("item", "")),
			_get_recipe_amount(entry)
		)
	for raw_entry in recipe.get("saidas", []):
		if raw_entry is not Dictionary:
			continue
		var entry: Dictionary = raw_entry
		var item_id: String = str(entry.get("item", ""))
		var amount := _get_recipe_amount(entry)
		if not InventoryUtils.can_add_item_amount_to_slot(simulated_inventory, MACHINE_OUTPUT_SLOT_LABEL, item_id, amount):
			return false
		InventoryUtils.add_item_amount_to_slot(simulated_inventory, MACHINE_OUTPUT_SLOT_LABEL, item_id, amount)
	return true


func _has_recipe_outputs(recipe: Dictionary) -> bool:
	var inventory: Dictionary = get_meta("inventory_data", {})
	for raw_entry in recipe.get("saidas", []):
		if raw_entry is not Dictionary:
			continue
		var entry: Dictionary = raw_entry
		if InventoryUtils.get_item_amount_in_slot(inventory, MACHINE_OUTPUT_SLOT_LABEL, str(entry.get("item", ""))) > 0.0:
			return true
	return false


func _ensure_machine_state() -> void:
	if not _is_machine():
		return

	if not has_meta("machine_state"):
		set_meta("machine_state", MACHINE_STATE_WAITING)
	if not has_meta("machine_progress_ms"):
		set_meta("machine_progress_ms", 0.0)
	_refresh_machine_label()


func _set_machine_state(state: String) -> void:
	if str(get_meta("machine_state", "")) == state:
		return
	set_meta("machine_state", state)
	_refresh_machine_label()


func _refresh_machine_label() -> void:
	if not _is_machine():
		return

	var recipe_id: String = str(get_meta("recipe_id", ""))
	var recipe := RecipeDatabase.get_recipe(recipe_id)
	var recipe_name: String = str(recipe.get("id", recipe_id)).capitalize()
	var state: String = _format_machine_state(str(get_meta("machine_state", MACHINE_STATE_WAITING)))
	if recipe_name.is_empty():
		set_secondary_label(state)
	else:
		set_secondary_label("%s | %s" % [recipe_name, state])


func _format_machine_state(state: String) -> String:
	if state == MACHINE_STATE_SUPPLIED:
		return "Abastecida"
	if state == MACHINE_STATE_PRODUCING:
		return "Produzindo"
	if state == MACHINE_STATE_READY:
		return "Pronta"
	return "Aguardando"


func _get_recipe_amount(entry: Dictionary) -> float:
	var amount := float(entry.get("quantidade", 0.0))
	if amount <= 0.0:
		return 0.0
	return amount


func _is_machine() -> bool:
	return str(get_meta("entity_id", "")) == "maquina"
