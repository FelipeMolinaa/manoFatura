extends Node2D

const EntityDatabase = preload("res://scripts/data/entity_database.gd")

const MODE_CAMERA := "Camera"
const MODE_BUILD := "Construir"
const ZOOM_STEP := 0.1
const MIN_ZOOM := 0.5
const MAX_ZOOM := 2.5
const BUILD_SCENES := {
	"maquina": preload("res://scenes/entities/machine.tscn"),
	"bau": preload("res://scenes/entities/chest.tscn"),
	"fonte_aco": preload("res://scenes/entities/steel_source.tscn"),
	"vendedor": preload("res://scenes/entities/vendor.tscn"),
}

@onready var camera_button: Button = $CanvasLayer/HUD/BottomBar/Margin/Row/CameraButton
@onready var build_button: Button = $CanvasLayer/HUD/BottomBar/Margin/Row/BuildButton
@onready var mode_label: Label = $CanvasLayer/HUD/ModeLabel
@onready var bottom_bar: PanelContainer = $CanvasLayer/HUD/BottomBar
@onready var camera_2d: Camera2D = $World/Camera2D
@onready var grid_overlay = $World/GridOverlay
@onready var entities_container: Node2D = $World/Entities
@onready var build_menu: PanelContainer = $CanvasLayer/HUD/BuildMenu
@onready var build_menu_title: Label = $CanvasLayer/HUD/BuildMenu/BuildMenuMargin/BuildMenuColumn/BuildMenuTitle
@onready var machine_card: Button = $CanvasLayer/HUD/BuildMenu/BuildMenuMargin/BuildMenuColumn/BuildMenuGrid/MachineCard
@onready var chest_card: Button = $CanvasLayer/HUD/BuildMenu/BuildMenuMargin/BuildMenuColumn/BuildMenuGrid/ChestCard
@onready var steel_source_card: Button = $CanvasLayer/HUD/BuildMenu/BuildMenuMargin/BuildMenuColumn/BuildMenuGrid/SteelSourceCard
@onready var vendor_card: Button = $CanvasLayer/HUD/BuildMenu/BuildMenuMargin/BuildMenuColumn/BuildMenuGrid/VendorCard
@onready var build_selection_label: Label = $CanvasLayer/HUD/BuildMenu/BuildMenuMargin/BuildMenuColumn/BuildSelectionLabel

var current_mode := MODE_CAMERA
var is_panning := false
var selected_building_id := "maquina"
var occupied_cells: Array[Vector2i] = []


func _ready() -> void:
	camera_button.pressed.connect(_on_camera_pressed)
	build_button.pressed.connect(_on_build_pressed)
	machine_card.pressed.connect(_on_machine_card_pressed)
	chest_card.pressed.connect(_on_chest_card_pressed)
	steel_source_card.pressed.connect(_on_steel_source_card_pressed)
	vendor_card.pressed.connect(_on_vendor_card_pressed)
	grid_overlay.placement_requested.connect(_on_grid_placement_requested)
	_apply_theme()
	_refresh_grid_build_preview()
	_refresh_grid_occupancy()
	_set_mode(current_mode)


func _on_camera_pressed() -> void:
	_set_mode(MODE_CAMERA)


func _on_build_pressed() -> void:
	_set_mode(MODE_BUILD)


func _on_machine_card_pressed() -> void:
	selected_building_id = "maquina"
	_update_build_selection_ui()
	_refresh_grid_build_preview()


func _on_chest_card_pressed() -> void:
	selected_building_id = "bau"
	_update_build_selection_ui()
	_refresh_grid_build_preview()


func _on_steel_source_card_pressed() -> void:
	selected_building_id = "fonte_aco"
	_update_build_selection_ui()
	_refresh_grid_build_preview()


func _on_vendor_card_pressed() -> void:
	selected_building_id = "vendedor"
	_update_build_selection_ui()
	_refresh_grid_build_preview()


func _on_grid_placement_requested(cell: Vector2i) -> void:
	var definition := _get_build_definition(selected_building_id)
	var size: Vector2i = definition["size"]

	if not grid_overlay.is_area_free(cell, size):
		return

	var entity_scene: PackedScene = definition["scene"]
	var instance := entity_scene.instantiate() as Node2D
	instance.position = grid_overlay.get_cell_world_position(cell)
	entities_container.add_child(instance)

	for y in range(size.y):
		for x in range(size.x):
			occupied_cells.append(cell + Vector2i(x, y))

	_refresh_grid_occupancy()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_apply_zoom(-ZOOM_STEP)
			get_viewport().set_input_as_handled()
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_apply_zoom(ZOOM_STEP)
			get_viewport().set_input_as_handled()
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and Input.is_key_pressed(KEY_SPACE):
				is_panning = true
				grid_overlay.set("block_input", true)
				get_viewport().set_input_as_handled()
				return
			if not event.pressed and is_panning:
				is_panning = false
				grid_overlay.set("block_input", false)
				get_viewport().set_input_as_handled()
				return

	if event is InputEventMouseMotion and is_panning:
		camera_2d.position -= event.relative / camera_2d.zoom.x
		get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and not event.pressed and event.keycode == KEY_SPACE and is_panning:
		is_panning = false
		grid_overlay.set("block_input", false)
		get_viewport().set_input_as_handled()


func _set_mode(mode: String) -> void:
	current_mode = mode
	mode_label.text = "Modo atual: %s" % current_mode
	grid_overlay.set("build_mode_enabled", current_mode == MODE_BUILD)
	build_menu.visible = current_mode == MODE_BUILD
	_update_mode_ui()
	_update_build_selection_ui()


func _apply_theme() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("111827")
	panel_style.border_width_top = 1
	panel_style.border_color = Color("334155")
	panel_style.corner_radius_top_left = 20
	panel_style.corner_radius_top_right = 20
	panel_style.shadow_color = Color(0, 0, 0, 0.25)
	panel_style.shadow_size = 10
	panel_style.shadow_offset = Vector2(0, -2)
	bottom_bar.add_theme_stylebox_override("panel", panel_style)

	var side_panel_style := StyleBoxFlat.new()
	side_panel_style.bg_color = Color("0f172a")
	side_panel_style.border_color = Color("334155")
	side_panel_style.border_width_left = 1
	side_panel_style.border_width_top = 1
	side_panel_style.border_width_right = 1
	side_panel_style.border_width_bottom = 1
	side_panel_style.corner_radius_top_left = 18
	side_panel_style.corner_radius_top_right = 18
	side_panel_style.corner_radius_bottom_left = 18
	side_panel_style.corner_radius_bottom_right = 18
	side_panel_style.shadow_color = Color(0, 0, 0, 0.25)
	side_panel_style.shadow_size = 10
	side_panel_style.shadow_offset = Vector2(2, 4)
	build_menu.add_theme_stylebox_override("panel", side_panel_style)

	var default_button := _build_button_style(Color("1e293b"), Color("334155"))
	var hover_button := _build_button_style(Color("334155"), Color("475569"))
	var selected_button := _build_button_style(Color("e2e8f0"), Color("f8fafc"))

	for button in [camera_button, build_button]:
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_color_override("font_color", Color("e5e7eb"))
		button.add_theme_color_override("font_hover_color", Color("f8fafc"))
		button.add_theme_color_override("font_pressed_color", Color("f8fafc"))
		button.add_theme_stylebox_override("normal", default_button)
		button.add_theme_stylebox_override("hover", hover_button)
		button.add_theme_stylebox_override("pressed", hover_button)
		button.focus_mode = Control.FOCUS_NONE

	mode_label.add_theme_font_size_override("font_size", 28)
	mode_label.add_theme_color_override("font_color", Color("e2e8f0"))
	build_menu_title.add_theme_font_size_override("font_size", 22)
	build_menu_title.add_theme_color_override("font_color", Color("f8fafc"))
	build_selection_label.add_theme_font_size_override("font_size", 16)
	build_selection_label.add_theme_color_override("font_color", Color("cbd5e1"))

	for card in [machine_card, chest_card, steel_source_card]:
		card.add_theme_font_size_override("font_size", 17)
		card.add_theme_color_override("font_color", Color("e2e8f0"))
		card.add_theme_color_override("font_hover_color", Color("f8fafc"))
		card.add_theme_color_override("font_pressed_color", Color("f8fafc"))
		card.add_theme_stylebox_override("normal", _build_card_style(Color("162033"), Color("334155")))
		card.add_theme_stylebox_override("hover", _build_card_style(Color("1e293b"), Color("64748b")))
		card.add_theme_stylebox_override("pressed", _build_card_style(Color("0f766e"), Color("14b8a6")))
		card.focus_mode = Control.FOCUS_NONE

	vendor_card.add_theme_font_size_override("font_size", 17)
	vendor_card.add_theme_color_override("font_color", Color("e2e8f0"))
	vendor_card.add_theme_color_override("font_hover_color", Color("f8fafc"))
	vendor_card.add_theme_color_override("font_pressed_color", Color("f8fafc"))
	vendor_card.add_theme_stylebox_override("normal", _build_card_style(Color("162033"), Color("334155")))
	vendor_card.add_theme_stylebox_override("hover", _build_card_style(Color("1e293b"), Color("64748b")))
	vendor_card.add_theme_stylebox_override("pressed", _build_card_style(Color("0f766e"), Color("14b8a6")))
	vendor_card.focus_mode = Control.FOCUS_NONE

	camera_button.set_meta("default_style", default_button)
	camera_button.set_meta("selected_style", selected_button)
	build_button.set_meta("default_style", default_button)
	build_button.set_meta("selected_style", selected_button)
	machine_card.set_meta("default_style", _build_card_style(Color("162033"), Color("334155")))
	machine_card.set_meta("selected_style", _build_card_style(Color("dbeafe"), Color("93c5fd")))
	chest_card.set_meta("default_style", _build_card_style(Color("162033"), Color("334155")))
	chest_card.set_meta("selected_style", _build_card_style(Color("fef3c7"), Color("f59e0b")))
	steel_source_card.set_meta("default_style", _build_card_style(Color("162033"), Color("334155")))
	steel_source_card.set_meta("selected_style", _build_card_style(Color("d1fae5"), Color("34d399")))
	vendor_card.set_meta("default_style", _build_card_style(Color("162033"), Color("334155")))
	vendor_card.set_meta("selected_style", _build_card_style(Color("fee2e2"), Color("f87171")))


func _apply_zoom(delta: float) -> void:
	var next_zoom := clampf(camera_2d.zoom.x + delta, MIN_ZOOM, MAX_ZOOM)
	camera_2d.zoom = Vector2(next_zoom, next_zoom)


func _update_build_selection_ui() -> void:
	var entity_definition := EntityDatabase.get_entity(selected_building_id)
	build_selection_label.text = "Selecionado: %s" % entity_definition.get("nome", selected_building_id)
	_apply_button_selection(machine_card, selected_building_id == "maquina")
	_apply_button_selection(chest_card, selected_building_id == "bau")
	_apply_button_selection(steel_source_card, selected_building_id == "fonte_aco")
	_apply_button_selection(vendor_card, selected_building_id == "vendedor")


func _update_mode_ui() -> void:
	_apply_button_selection(camera_button, current_mode == MODE_CAMERA)
	_apply_button_selection(build_button, current_mode == MODE_BUILD)


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
	style.content_margin_left = 12
	style.content_margin_top = 8
	style.content_margin_right = 12
	style.content_margin_bottom = 8
	return style


func _build_card_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_right = 14
	style.corner_radius_bottom_left = 14
	style.content_margin_left = 10
	style.content_margin_top = 10
	style.content_margin_right = 10
	style.content_margin_bottom = 10
	return style


func _apply_button_selection(button: Button, is_selected: bool) -> void:
	var default_style: StyleBoxFlat = button.get_meta("default_style")
	var selected_style: StyleBoxFlat = button.get_meta("selected_style")
	var normal_style := selected_style if is_selected else default_style
	var hover_style := selected_style if is_selected else _build_button_style(Color("334155"), Color("475569"))
	var pressed_style := selected_style if is_selected else hover_style

	if button == machine_card or button == chest_card or button == steel_source_card or button == vendor_card:
		hover_style = selected_style if is_selected else _build_card_style(Color("1e293b"), Color("64748b"))
		pressed_style = selected_style if is_selected else _build_card_style(Color("0f766e"), Color("14b8a6"))

	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)

	if is_selected:
		button.add_theme_color_override("font_color", Color("0f172a"))
		button.add_theme_color_override("font_hover_color", Color("0f172a"))
		button.add_theme_color_override("font_pressed_color", Color("0f172a"))
	else:
		button.add_theme_color_override("font_color", Color("e2e8f0"))
		button.add_theme_color_override("font_hover_color", Color("f8fafc"))
		button.add_theme_color_override("font_pressed_color", Color("f8fafc"))


func _refresh_grid_build_preview() -> void:
	var definition := _get_build_definition(selected_building_id)
	grid_overlay.set_build_preview(definition["size"], definition["color"])


func _refresh_grid_occupancy() -> void:
	grid_overlay.set_occupied_cells(occupied_cells)


func _get_build_definition(entity_id: String) -> Dictionary:
	var entity_definition := EntityDatabase.get_entity(entity_id)
	return {
		"id": entity_definition["id"],
		"name": entity_definition["nome"],
		"size": entity_definition["tamanho"],
		"color": entity_definition["cor"],
		"scene": BUILD_SCENES[entity_id],
	}
