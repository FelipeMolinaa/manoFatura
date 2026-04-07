extends PanelContainer

const EntityDatabase = preload("res://scripts/data/entity_database.gd")
const InventoryUtils = preload("res://scripts/data/inventory_utils.gd")
const ItemDatabase = preload("res://scripts/data/item_database.gd")
const RecipeDatabase = preload("res://scripts/data/recipe_database.gd")

const POINT_ENTITY_SEARCH_RADIUS := 96.0
const ACTION_IDS: Array[String] = [WorkerAgent.POINT_ACTION_PICKUP, WorkerAgent.POINT_ACTION_DROPOFF]
const INFO_TAB_INDEX := 0
const POINT_A_TAB_INDEX := 1
const POINT_B_TAB_INDEX := 2

signal worker_action_requested(worker_id: String, action_id: String)
signal entity_move_requested(entity: Node2D)
signal entity_destroy_requested(entity: Node2D)
signal entity_config_requested(entity: Node2D)
signal worker_point_config_changed(worker_id: String, point_kind: String, config: Dictionary)

@onready var title_label: Label = $Margin/Column/Header/TitleLabel
@onready var subtitle_label: Label = $Margin/Column/Header/SubtitleLabel
@onready var tabs: TabContainer = $Margin/Column/Tabs
@onready var info_list: VBoxContainer = $Margin/Column/Tabs/Info/InfoSection/InfoList
@onready var inventory_summary_label: Label = $Margin/Column/Tabs/Info/InventorySection/InventorySummaryLabel
@onready var inventory_list: VBoxContainer = $Margin/Column/Tabs/Info/InventorySection/InventoryList
@onready var entity_actions: VBoxContainer = $Margin/Column/Tabs/Info/ActionsSection/EntityActions
@onready var configure_entity_button: Button = $Margin/Column/Tabs/Info/ActionsSection/EntityActions/ConfigureEntityButton
@onready var move_entity_button: Button = $Margin/Column/Tabs/Info/ActionsSection/EntityActions/MoveEntityButton
@onready var destroy_entity_button: Button = $Margin/Column/Tabs/Info/ActionsSection/EntityActions/DestroyEntityButton
@onready var worker_actions: VBoxContainer = $Margin/Column/Tabs/Info/ActionsSection/WorkerActions
@onready var reposition_worker_button: Button = $Margin/Column/Tabs/Info/ActionsSection/WorkerActions/RepositionWorkerButton
@onready var point_a_config: VBoxContainer = $Margin/Column/Tabs/PontoA/PointAConfig
@onready var point_a_button: Button = $Margin/Column/Tabs/PontoA/PointAConfig/PointAButton
@onready var point_a_local_label: Label = $Margin/Column/Tabs/PontoA/PointAConfig/PointALocalLabel
@onready var point_a_action_row: HBoxContainer = $Margin/Column/Tabs/PontoA/PointAConfig/PointAActionRow
@onready var point_a_action_option: OptionButton = $Margin/Column/Tabs/PontoA/PointAConfig/PointAActionRow/PointAActionOption
@onready var point_a_quantity_row: HBoxContainer = $Margin/Column/Tabs/PontoA/PointAConfig/PointAQuantityRow
@onready var point_a_quantity_spin: SpinBox = $Margin/Column/Tabs/PontoA/PointAConfig/PointAQuantityRow/PointAQuantitySpin
@onready var point_a_mode_button: Button = $Margin/Column/Tabs/PontoA/PointAConfig/PointAQuantityRow/PointAModeButton
@onready var point_b_config: VBoxContainer = $Margin/Column/Tabs/PontoB/PointBConfig
@onready var point_b_button: Button = $Margin/Column/Tabs/PontoB/PointBConfig/PointBButton
@onready var point_b_local_label: Label = $Margin/Column/Tabs/PontoB/PointBConfig/PointBLocalLabel
@onready var point_b_action_row: HBoxContainer = $Margin/Column/Tabs/PontoB/PointBConfig/PointBActionRow
@onready var point_b_action_option: OptionButton = $Margin/Column/Tabs/PontoB/PointBConfig/PointBActionRow/PointBActionOption
@onready var point_b_quantity_row: HBoxContainer = $Margin/Column/Tabs/PontoB/PointBConfig/PointBQuantityRow
@onready var point_b_quantity_spin: SpinBox = $Margin/Column/Tabs/PontoB/PointBConfig/PointBQuantityRow/PointBQuantitySpin
@onready var point_b_mode_button: Button = $Margin/Column/Tabs/PontoB/PointBConfig/PointBQuantityRow/PointBModeButton

var _selected_entity: Node2D
var _selected_worker: WorkerAgent
var _entities_container: Node2D
var _is_updating_point_controls := false
var _point_quantity_modes: Dictionary = {
	"point_a": WorkerAgent.QUANTITY_MODE_AMOUNT,
	"point_b": WorkerAgent.QUANTITY_MODE_AMOUNT,
}


func _ready() -> void:
	visible = false
	_apply_theme()
	_setup_tabs()
	_set_point_tabs_visible(false)
	_setup_point_config_controls()
	configure_entity_button.pressed.connect(func() -> void:
		if is_instance_valid(_selected_entity):
			entity_config_requested.emit(_selected_entity)
	)
	move_entity_button.pressed.connect(func() -> void:
		if is_instance_valid(_selected_entity):
			entity_move_requested.emit(_selected_entity)
	)
	destroy_entity_button.pressed.connect(func() -> void:
		if is_instance_valid(_selected_entity):
			entity_destroy_requested.emit(_selected_entity)
	)
	reposition_worker_button.pressed.connect(func() -> void:
		if is_instance_valid(_selected_worker):
			worker_action_requested.emit(_selected_worker.worker_id, "position")
	)
	point_a_button.pressed.connect(func() -> void:
		if is_instance_valid(_selected_worker):
			worker_action_requested.emit(_selected_worker.worker_id, "point_a")
	)
	point_b_button.pressed.connect(func() -> void:
		if is_instance_valid(_selected_worker):
			worker_action_requested.emit(_selected_worker.worker_id, "point_b")
	)


func _setup_tabs() -> void:
	tabs.set_tab_title(INFO_TAB_INDEX, "Info")
	tabs.set_tab_title(POINT_A_TAB_INDEX, "Ponto A")
	tabs.set_tab_title(POINT_B_TAB_INDEX, "Ponto B")
	tabs.current_tab = INFO_TAB_INDEX


func _set_point_tabs_visible(are_visible: bool) -> void:
	tabs.set_tab_hidden(POINT_A_TAB_INDEX, not are_visible)
	tabs.set_tab_hidden(POINT_B_TAB_INDEX, not are_visible)
	if not are_visible and tabs.current_tab != INFO_TAB_INDEX:
		tabs.current_tab = INFO_TAB_INDEX


func set_entities_container(entities_container: Node2D) -> void:
	_entities_container = entities_container


func show_for_entity(entity: Node2D) -> void:
	if not is_instance_valid(entity):
		clear_selection()
		return

	_selected_entity = entity
	_selected_worker = null
	_populate_entity_details(entity)
	visible = true


func show_for_worker(worker: WorkerAgent) -> void:
	if not is_instance_valid(worker):
		clear_selection()
		return

	var should_preserve_tab: bool = visible and is_instance_valid(_selected_worker) and _selected_worker.worker_id == worker.worker_id
	var preserved_tab: int = tabs.current_tab
	_selected_entity = null
	_selected_worker = worker
	_populate_worker_details(worker)
	if should_preserve_tab:
		tabs.current_tab = clampi(preserved_tab, 0, tabs.get_child_count() - 1)
	else:
		tabs.current_tab = INFO_TAB_INDEX
	visible = true


func refresh_selection() -> void:
	if is_instance_valid(_selected_entity):
		show_for_entity(_selected_entity)
		return
	if is_instance_valid(_selected_worker):
		show_for_worker(_selected_worker)
		return
	clear_selection()


func clear_selection() -> void:
	_selected_entity = null
	_selected_worker = null
	visible = false


func _populate_entity_details(entity: Node2D) -> void:
	var entity_id: String = str(entity.get_meta("entity_id", ""))
	var entity_definition: Dictionary = EntityDatabase.get_entity(entity_id)
	var entity_size: Vector2i = entity_definition.get("tamanho", Vector2i.ONE)
	var inventory: Dictionary = InventoryUtils.normalize_inventory(entity.get_meta("inventory_data", {}), [], -1.0)
	var recipe_or_inventory_text: String = "Inventario: %d slots" % int(inventory.get("slot_count", 0))
	var machine_state_text := ""
	if entity_id == "maquina":
		var recipe_id: String = str(entity.get_meta("recipe_id", "Nenhuma"))
		var recipe := RecipeDatabase.get_recipe(recipe_id)
		recipe_or_inventory_text = "Receita: %s" % str(recipe.get("id", recipe_id)).capitalize()
		if entity.has_method("get_machine_status_text"):
			machine_state_text = "Estado: %s" % entity.get_machine_status_text()
		else:
			machine_state_text = "Estado: %s" % str(entity.get_meta("machine_state", "aguardando")).capitalize()

	title_label.text = str(entity_definition.get("nome", "Entidade"))
	subtitle_label.text = "Entidade"
	entity_actions.visible = true
	worker_actions.visible = false
	tabs.current_tab = INFO_TAB_INDEX
	_set_point_tabs_visible(false)
	configure_entity_button.visible = entity_id == "maquina"

	var info_rows: Array[String] = [
		"Tipo: %s" % entity_id.capitalize(),
		"Tamanho: %dx%d" % [entity_size.x, entity_size.y],
		"Posicao: (%.0f, %.0f)" % [entity.global_position.x, entity.global_position.y],
		recipe_or_inventory_text,
	]
	if not machine_state_text.is_empty():
		info_rows.append(machine_state_text)
	_set_info_rows(info_rows)
	_set_inventory_rows(inventory)


func _populate_worker_details(worker: WorkerAgent) -> void:
	var inventory: Dictionary = worker.get_inventory_data()
	var current_weight: float = worker.get_inventory_total_weight()
	var max_weight: float = worker.get_max_carry_weight()

	title_label.text = worker.worker_name
	subtitle_label.text = "Funcionario"
	entity_actions.visible = false
	worker_actions.visible = true
	_set_point_tabs_visible(true)

	_set_info_rows([
		"Idade: %d" % worker.worker_age,
		"Genero: %s" % worker.worker_gender,
		"Velocidade: %.0f" % worker.speed,
		"Forca: %.1f" % worker.strength,
		"Posicao: (%.0f, %.0f)" % [worker.global_position.x, worker.global_position.y],
		"Ponto A: %s" % _format_point_location(worker, "point_a"),
		"Ponto B: %s" % _format_point_location(worker, "point_b"),
		"Carga: %.2f / %.2f kg" % [current_weight, max_weight],
	])
	_populate_point_config_controls(worker)
	_set_inventory_rows(inventory)


func _setup_point_config_controls() -> void:
	_configure_action_option(point_a_action_option)
	_configure_action_option(point_b_action_option)

	point_a_action_option.item_selected.connect(func(_index: int) -> void:
		_emit_point_config_changed("point_a")
	)
	point_b_action_option.item_selected.connect(func(_index: int) -> void:
		_emit_point_config_changed("point_b")
	)
	point_a_quantity_spin.value_changed.connect(func(_value: float) -> void:
		_emit_point_config_changed("point_a")
	)
	point_b_quantity_spin.value_changed.connect(func(_value: float) -> void:
		_emit_point_config_changed("point_b")
	)
	point_a_mode_button.pressed.connect(func() -> void:
		_toggle_quantity_mode("point_a")
	)
	point_b_mode_button.pressed.connect(func() -> void:
		_toggle_quantity_mode("point_b")
	)


func _configure_action_option(option_button: OptionButton) -> void:
	option_button.clear()
	option_button.add_item("Pegar", 0)
	option_button.add_item("Largar", 1)
	option_button.focus_mode = Control.FOCUS_NONE


func _populate_point_config_controls(worker: WorkerAgent) -> void:
	_is_updating_point_controls = true
	_populate_single_point_config(worker, "point_a")
	_populate_single_point_config(worker, "point_b")
	_is_updating_point_controls = false


func _populate_single_point_config(worker: WorkerAgent, point_kind: String) -> void:
	var config: Dictionary = worker.get_point_config(point_kind)
	var action: String = str(config.get("action", WorkerAgent.POINT_ACTION_PICKUP))
	var quantity_mode: String = str(config.get("quantity_mode", WorkerAgent.QUANTITY_MODE_AMOUNT))
	var quantity_value: float = float(config.get("quantity_value", 1.0))
	_point_quantity_modes[point_kind] = quantity_mode

	var local_label: Label = point_a_local_label if point_kind == "point_a" else point_b_local_label
	var action_row: HBoxContainer = point_a_action_row if point_kind == "point_a" else point_b_action_row
	var action_option: OptionButton = point_a_action_option if point_kind == "point_a" else point_b_action_option
	var quantity_row: HBoxContainer = point_a_quantity_row if point_kind == "point_a" else point_b_quantity_row
	var quantity_spin: SpinBox = point_a_quantity_spin if point_kind == "point_a" else point_b_quantity_spin
	var mode_button: Button = point_a_mode_button if point_kind == "point_a" else point_b_mode_button
	var point_entity: Node2D = _get_worker_point_entity(worker, point_kind)
	var has_configurable_location: bool = point_entity != null and _entity_supports_point_config(point_entity)

	if point_entity == null:
		local_label.text = ""
	else:
		local_label.text = "Local: %s" % _get_entity_display_name(point_entity)
	action_row.visible = has_configurable_location
	quantity_row.visible = has_configurable_location
	if not has_configurable_location:
		return

	action_option.select(maxi(ACTION_IDS.find(action), 0))
	quantity_spin.value = quantity_value
	_apply_quantity_mode_to_controls(quantity_spin, mode_button, quantity_mode)


func _toggle_quantity_mode(point_kind: String) -> void:
	if _is_updating_point_controls:
		return

	var current_mode: String = str(_point_quantity_modes.get(point_kind, WorkerAgent.QUANTITY_MODE_AMOUNT))
	var next_mode: String = WorkerAgent.QUANTITY_MODE_PERCENT
	if current_mode == WorkerAgent.QUANTITY_MODE_PERCENT:
		next_mode = WorkerAgent.QUANTITY_MODE_AMOUNT
	_point_quantity_modes[point_kind] = next_mode

	var mode_button: Button = point_a_mode_button if point_kind == "point_a" else point_b_mode_button
	var quantity_spin: SpinBox = point_a_quantity_spin if point_kind == "point_a" else point_b_quantity_spin
	_is_updating_point_controls = true
	_apply_quantity_mode_to_controls(quantity_spin, mode_button, next_mode)
	_is_updating_point_controls = false
	_emit_point_config_changed(point_kind)


func _apply_quantity_mode_to_controls(quantity_spin: SpinBox, mode_button: Button, quantity_mode: String) -> void:
	var is_percent: bool = quantity_mode == WorkerAgent.QUANTITY_MODE_PERCENT
	mode_button.text = "%" if is_percent else "un"
	quantity_spin.max_value = 100.0 if is_percent else 100000.0
	if is_percent:
		quantity_spin.value = minf(quantity_spin.value, 100.0)


func _emit_point_config_changed(point_kind: String) -> void:
	if _is_updating_point_controls or not is_instance_valid(_selected_worker):
		return

	var action_option: OptionButton = point_a_action_option if point_kind == "point_a" else point_b_action_option
	var quantity_spin: SpinBox = point_a_quantity_spin if point_kind == "point_a" else point_b_quantity_spin
	var selected_action_index: int = clampi(action_option.selected, 0, ACTION_IDS.size() - 1)
	var config: Dictionary = {
		"action": ACTION_IDS[selected_action_index],
		"quantity_mode": str(_point_quantity_modes.get(point_kind, WorkerAgent.QUANTITY_MODE_AMOUNT)),
		"quantity_value": quantity_spin.value,
		"item_id": WorkerAgent.DEFAULT_TRANSFER_ITEM_ID,
	}
	worker_point_config_changed.emit(_selected_worker.worker_id, point_kind, config)


func _format_point_location(worker: WorkerAgent, point_kind: String) -> String:
	if point_kind == "point_a" and not worker.has_point_a:
		return ""
	if point_kind == "point_b" and not worker.has_point_b:
		return ""

	var entity: Node2D = _get_worker_point_entity(worker, point_kind)
	if entity != null:
		return _get_entity_display_name(entity)
	return ""


func _get_worker_point_entity(worker: WorkerAgent, point_kind: String) -> Node2D:
	if point_kind == "point_a" and not worker.has_point_a:
		return null
	if point_kind == "point_b" and not worker.has_point_b:
		return null
	return _get_entity_near_position(worker.get_target_position(point_kind))


func _entity_supports_point_config(entity: Node2D) -> bool:
	if entity == null:
		return false
	return str(entity.get_meta("entity_id", "")) == "fonte_aco" or entity.has_meta("inventory_data")


func _get_entity_display_name(entity: Node2D) -> String:
	var entity_id: String = str(entity.get_meta("entity_id", ""))
	var entity_definition: Dictionary = EntityDatabase.get_entity(entity_id)
	return str(entity_definition.get("nome", entity_id.capitalize()))


func _get_entity_near_position(point_position: Vector2) -> Node2D:
	if _entities_container == null or not is_instance_valid(_entities_container):
		return null

	var nearest_entity: Node2D
	var nearest_distance: float = INF
	for entity in _entities_container.get_children():
		var entity_node := entity as Node2D
		if entity_node == null or not entity_node.has_method("get_global_bounds"):
			continue

		var distance: float = _distance_to_rect(point_position, entity_node.get_global_bounds())
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_entity = entity_node

	if nearest_distance <= POINT_ENTITY_SEARCH_RADIUS:
		return nearest_entity
	return null


func _distance_to_rect(point: Vector2, rect: Rect2) -> float:
	var nearest_point: Vector2 = Vector2(
		clampf(point.x, rect.position.x, rect.end.x),
		clampf(point.y, rect.position.y, rect.end.y)
	)
	return point.distance_to(nearest_point)


func _set_info_rows(rows: Array[String]) -> void:
	for child in info_list.get_children():
		child.queue_free()

	for row_text in rows:
		var label := Label.new()
		label.text = row_text
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 15)
		label.add_theme_color_override("font_color", Color("dbe4f0"))
		info_list.add_child(label)


func _set_inventory_rows(inventory: Dictionary) -> void:
	for child in inventory_list.get_children():
		child.queue_free()

	var slot_count: int = int(inventory.get("slot_count", 0))
	var total_amount: int = InventoryUtils.get_total_amount(inventory)
	var total_weight: float = InventoryUtils.get_total_weight(inventory)
	var max_weight: float = float(inventory.get("max_weight", -1.0))
	var max_amount: int = int(inventory.get("max_amount", -1))
	var amount_summary: String = "%d item(ns)" % total_amount
	if max_amount > 0:
		amount_summary = "%d / %d item(ns)" % [total_amount, max_amount]
	if max_weight > 0.0:
		inventory_summary_label.text = "%d slot(s) | %s | %.2f / %.2f kg" % [slot_count, amount_summary, total_weight, max_weight]
	else:
		inventory_summary_label.text = "%d slot(s) | %s | %.2f kg" % [slot_count, amount_summary, total_weight]

	for raw_slot in inventory.get("slots", []):
		if raw_slot is not Dictionary:
			continue

		var slot: Dictionary = raw_slot
		var item_id: String = str(slot.get("item_id", ""))
		var amount: float = maxf(float(slot.get("amount", 0.0)), 0.0)
		var slot_name: String = str(slot.get("label", "Slot"))
		var row := Label.new()
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_theme_font_size_override("font_size", 15)
		row.add_theme_color_override("font_color", Color("e5eef9"))

		if item_id.is_empty() or amount <= 0.0:
			row.text = "%s: vazio" % slot_name
		else:
			var item_definition: Dictionary = ItemDatabase.get_item(item_id)
			var item_name: String = str(item_definition.get("nome", item_id))
			var item_weight: float = float(item_definition.get("peso", 0.0))
			row.text = "%s: %s x%s (%.2f kg)" % [slot_name, item_name, _format_amount(amount), item_weight * amount]

		inventory_list.add_child(row)

	if inventory_list.get_child_count() == 0:
		var empty_label := Label.new()
		empty_label.text = "Esta selecao nao possui inventario."
		empty_label.add_theme_font_size_override("font_size", 15)
		empty_label.add_theme_color_override("font_color", Color("94a3b8"))
		inventory_list.add_child(empty_label)


func _apply_theme() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("0f172a")
	panel_style.border_color = Color("334155")
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_width_right = 1
	panel_style.border_width_bottom = 1
	panel_style.corner_radius_top_left = 18
	panel_style.corner_radius_top_right = 18
	panel_style.corner_radius_bottom_left = 18
	panel_style.corner_radius_bottom_right = 18
	panel_style.shadow_color = Color(0, 0, 0, 0.25)
	panel_style.shadow_size = 10
	panel_style.shadow_offset = Vector2(2, 4)
	add_theme_stylebox_override("panel", panel_style)

	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color("f8fafc"))
	subtitle_label.add_theme_font_size_override("font_size", 15)
	subtitle_label.add_theme_color_override("font_color", Color("94a3b8"))
	inventory_summary_label.add_theme_font_size_override("font_size", 14)
	inventory_summary_label.add_theme_color_override("font_color", Color("cbd5e1"))

	for label in [$Margin/Column/Tabs/Info/InfoSection/InfoTitle, $Margin/Column/Tabs/Info/InventorySection/InventoryTitle, $Margin/Column/Tabs/Info/ActionsSection/ActionsTitle, $Margin/Column/Tabs/PontoA/PointAConfig/PointATitle, $Margin/Column/Tabs/PontoB/PointBConfig/PointBTitle]:
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color("f8fafc"))

	for button in [configure_entity_button, move_entity_button, destroy_entity_button, reposition_worker_button, point_a_button, point_b_button, point_a_mode_button, point_b_mode_button]:
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 15)
		button.add_theme_color_override("font_color", Color("e2e8f0"))
		button.add_theme_color_override("font_hover_color", Color("f8fafc"))
		button.add_theme_color_override("font_pressed_color", Color("f8fafc"))
		button.add_theme_stylebox_override("normal", _build_button_style(Color("1e293b"), Color("334155")))
		button.add_theme_stylebox_override("hover", _build_button_style(Color("334155"), Color("475569")))
		button.add_theme_stylebox_override("pressed", _build_button_style(Color("0f766e"), Color("14b8a6")))

	destroy_entity_button.add_theme_stylebox_override("pressed", _build_button_style(Color("7f1d1d"), Color("ef4444")))


func _build_button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 10
	style.content_margin_bottom = 8
	return style


func _format_amount(amount: float) -> String:
	if is_equal_approx(amount, roundf(amount)):
		return "%d" % int(roundf(amount))
	return "%.2f" % amount
