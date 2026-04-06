extends Control

const EntityDatabase = preload("res://scripts/data/entity_database.gd")

const MODE_CAMERA := "Camera"
const MODE_BUILD := "Construir"

signal mode_selected(mode: String)
signal build_selected(entity_id: String)

@onready var bottom_bar: PanelContainer = $BottomBar
@onready var camera_button: Button = $BottomBar/Margin/Row/CameraButton
@onready var build_button: Button = $BottomBar/Margin/Row/BuildButton
@onready var money_label: Label = $BottomBar/Margin/Row/MoneyLabel
@onready var mode_label: Label = $ModeLabel
@onready var build_menu: PanelContainer = $BuildMenu
@onready var build_menu_title: Label = $BuildMenu/BuildMenuMargin/BuildMenuColumn/BuildMenuTitle
@onready var machine_card: Button = $BuildMenu/BuildMenuMargin/BuildMenuColumn/BuildMenuGrid/MachineCard
@onready var chest_card: Button = $BuildMenu/BuildMenuMargin/BuildMenuColumn/BuildMenuGrid/ChestCard
@onready var steel_source_card: Button = $BuildMenu/BuildMenuMargin/BuildMenuColumn/BuildMenuGrid/SteelSourceCard
@onready var vendor_card: Button = $BuildMenu/BuildMenuMargin/BuildMenuColumn/BuildMenuGrid/VendorCard
@onready var build_selection_label: Label = $BuildMenu/BuildMenuMargin/BuildMenuColumn/BuildSelectionLabel

var current_mode := MODE_CAMERA
var selected_building_id := ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	camera_button.pressed.connect(func() -> void: mode_selected.emit(MODE_CAMERA))
	build_button.pressed.connect(func() -> void: mode_selected.emit(MODE_BUILD))
	machine_card.pressed.connect(func() -> void: build_selected.emit("maquina"))
	chest_card.pressed.connect(func() -> void: build_selected.emit("bau"))
	steel_source_card.pressed.connect(func() -> void: build_selected.emit("fonte_aco"))
	vendor_card.pressed.connect(func() -> void: build_selected.emit("vendedor"))
	_apply_theme()
	set_mode(current_mode)
	set_selected_building(selected_building_id)


func set_mode(mode: String) -> void:
	current_mode = mode
	mode_label.text = "Modo atual: %s" % current_mode
	build_menu.visible = current_mode == MODE_BUILD
	_update_mode_ui()


func set_selected_building(entity_id: String) -> void:
	selected_building_id = entity_id
	if selected_building_id.is_empty():
		build_selection_label.text = "Selecionado: Nenhum"
	else:
		var entity_definition := EntityDatabase.get_entity(selected_building_id)
		build_selection_label.text = "Selecionado: %s" % entity_definition.get("nome", selected_building_id)
	_apply_button_selection(machine_card, selected_building_id == "maquina")
	_apply_button_selection(chest_card, selected_building_id == "bau")
	_apply_button_selection(steel_source_card, selected_building_id == "fonte_aco")
	_apply_button_selection(vendor_card, selected_building_id == "vendedor")


func _update_mode_ui() -> void:
	_apply_button_selection(camera_button, current_mode == MODE_CAMERA)
	_apply_button_selection(build_button, current_mode == MODE_BUILD)


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
	money_label.add_theme_font_size_override("font_size", 18)
	money_label.add_theme_color_override("font_color", Color("f8fafc"))
	build_menu_title.add_theme_font_size_override("font_size", 22)
	build_menu_title.add_theme_color_override("font_color", Color("f8fafc"))
	build_selection_label.add_theme_font_size_override("font_size", 16)
	build_selection_label.add_theme_color_override("font_color", Color("cbd5e1"))

	for card in [machine_card, chest_card, steel_source_card, vendor_card]:
		card.add_theme_font_size_override("font_size", 17)
		card.add_theme_color_override("font_color", Color("e2e8f0"))
		card.add_theme_color_override("font_hover_color", Color("f8fafc"))
		card.add_theme_color_override("font_pressed_color", Color("f8fafc"))
		card.add_theme_stylebox_override("normal", _build_card_style(Color("162033"), Color("334155")))
		card.add_theme_stylebox_override("hover", _build_card_style(Color("1e293b"), Color("64748b")))
		card.add_theme_stylebox_override("pressed", _build_card_style(Color("0f766e"), Color("14b8a6")))
		card.focus_mode = Control.FOCUS_NONE

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


func set_money(current_money: int) -> void:
	money_label.text = "Dinheiro: $%d" % current_money
