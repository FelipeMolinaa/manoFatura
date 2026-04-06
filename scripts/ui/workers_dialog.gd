extends ConfirmationDialog

signal hire_requested(profile_id: String)
signal worker_action_requested(worker_id: String, action_id: String)
signal fire_requested(worker_id: String)

@onready var tab_container: TabContainer = $Margin/RootColumn/TabContainer
@onready var hired_list: VBoxContainer = $Margin/RootColumn/TabContainer/Contratados/Scroll/HiredList
@onready var available_list: VBoxContainer = $Margin/RootColumn/TabContainer/Disponiveis/Scroll/AvailableList
@onready var hired_empty_label: Label = $Margin/RootColumn/TabContainer/Contratados/HiredEmptyLabel
@onready var available_empty_label: Label = $Margin/RootColumn/TabContainer/Disponiveis/AvailableEmptyLabel


func _ready() -> void:
	title = "Funcionarios"
	get_ok_button().hide()
	get_cancel_button().text = "Fechar"


func show_with_data(hired_workers: Array[Dictionary], available_profiles: Array[Dictionary]) -> void:
	_rebuild_hired_list(hired_workers)
	_rebuild_available_list(available_profiles)
	popup_centered_ratio(0.72)


func _rebuild_hired_list(hired_workers: Array[Dictionary]) -> void:
	for child in hired_list.get_children():
		child.queue_free()

	hired_empty_label.visible = hired_workers.is_empty()
	if hired_empty_label.visible:
		return

	for worker_data in hired_workers:
		hired_list.add_child(_build_hired_card(worker_data))


func _rebuild_available_list(available_profiles: Array[Dictionary]) -> void:
	for child in available_list.get_children():
		child.queue_free()

	available_empty_label.visible = available_profiles.is_empty()
	if available_empty_label.visible:
		return

	for profile in available_profiles:
		available_list.add_child(_build_available_card(profile))


func _build_hired_card(worker_data: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.add_theme_constant_override("separation", 16)
	margin.add_child(row)

	var info_column := VBoxContainer.new()
	info_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_column.add_theme_constant_override("separation", 6)
	row.add_child(info_column)

	var name_label := Label.new()
	name_label.text = "%s, %s anos" % [worker_data.get("nome", "Funcionario"), str(worker_data.get("idade", "-"))]
	info_column.add_child(name_label)

	var details_label := Label.new()
	details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details_label.text = "Genero: %s | Velocidade: %s | Forca: %s | Ponto A: %s | Ponto B: %s" % [
		worker_data.get("genero", "-"),
		_format_decimal(worker_data.get("velocidade", 0.0)),
		_format_decimal(worker_data.get("forca", 0.0)),
		_format_point(worker_data.get("point_a")),
		_format_point(worker_data.get("point_b")),
	]
	info_column.add_child(details_label)

	var action_column := VBoxContainer.new()
	action_column.add_theme_constant_override("separation", 6)
	row.add_child(action_column)

	action_column.add_child(_build_action_button("Posicionar", worker_data.get("id", ""), "position"))
	action_column.add_child(_build_action_button("Configurar Ponto A", worker_data.get("id", ""), "point_a"))
	action_column.add_child(_build_action_button("Configurar Ponto B", worker_data.get("id", ""), "point_b"))

	var fire_button := Button.new()
	fire_button.text = "Demitir"
	fire_button.custom_minimum_size = Vector2(170, 0)
	fire_button.pressed.connect(func() -> void:
		fire_requested.emit(worker_data.get("id", ""))
	)
	action_column.add_child(fire_button)

	return panel


func _build_available_card(profile: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	margin.add_child(row)

	var info_column := VBoxContainer.new()
	info_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_column.add_theme_constant_override("separation", 6)
	row.add_child(info_column)

	var name_label := Label.new()
	name_label.text = "%s, %s anos" % [profile.get("nome", "Funcionario"), str(profile.get("idade", "-"))]
	info_column.add_child(name_label)

	var details_label := Label.new()
	details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details_label.text = "Genero: %s | Velocidade: %s | Forca: %s" % [
		profile.get("genero", "-"),
		_format_decimal(profile.get("velocidade", 0.0)),
		_format_decimal(profile.get("forca", 0.0)),
	]
	info_column.add_child(details_label)

	var hire_button := Button.new()
	hire_button.text = "Contratar"
	hire_button.custom_minimum_size = Vector2(140, 0)
	hire_button.pressed.connect(func() -> void:
		hire_requested.emit(profile.get("id", ""))
	)
	row.add_child(hire_button)

	return panel


func _build_action_button(label_text: String, worker_id: String, action_id: String) -> Button:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(170, 0)
	button.pressed.connect(func() -> void:
		worker_action_requested.emit(worker_id, action_id)
	)
	return button


func _format_point(value: Variant) -> String:
	if value == null:
		return "Nao definido"

	if value is Vector2:
		var point := value as Vector2
		return "(%d, %d)" % [roundi(point.x), roundi(point.y)]

	return str(value)


func _format_decimal(value: Variant) -> String:
	return "%.1f" % float(value)
