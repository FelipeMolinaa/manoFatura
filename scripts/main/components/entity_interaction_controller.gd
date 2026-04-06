extends Node

const EntityDatabase = preload("res://scripts/data/entity_database.gd")

signal worker_action_requested(worker_id: String, action_id: String)

@export_node_path("Node2D") var entities_container_path: NodePath
@export_node_path("Node2D") var workers_container_path: NodePath
@export_node_path("ConfirmationDialog") var confirmation_popup_path: NodePath
@export_node_path("PopupMenu") var entity_actions_menu_path: NodePath
@export_node_path("ConfirmationDialog") var entity_config_dialog_path: NodePath
@export_node_path("ConfirmationDialog") var worker_action_dialog_path: NodePath
@export_node_path("Node") var build_manager_path: NodePath

var _active := false
var _focused_entity: Node2D
var _focused_worker: WorkerAgent
var _context_entity: Node2D

@onready var entities_container: Node2D = get_node(entities_container_path) as Node2D
@onready var workers_container: Node2D = get_node(workers_container_path) as Node2D
@onready var confirmation_popup = get_node(confirmation_popup_path)
@onready var entity_actions_menu = get_node(entity_actions_menu_path)
@onready var entity_config_dialog = get_node(entity_config_dialog_path)
@onready var worker_action_dialog = get_node(worker_action_dialog_path)
@onready var build_manager = get_node(build_manager_path)


func _ready() -> void:
	confirmation_popup.action_confirmed.connect(_on_popup_action_confirmed)
	entity_actions_menu.destroy_requested.connect(_on_destroy_requested)
	entity_actions_menu.move_requested.connect(_on_move_requested)
	worker_action_dialog.action_selected.connect(_on_worker_action_selected)


func set_active(enabled: bool) -> void:
	_active = enabled
	if not _active:
		_set_focused_targets(null, null)
		_context_entity = null
		entity_actions_menu.hide()
		entity_config_dialog.hide()
		worker_action_dialog.hide()


func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return

	if Input.is_key_pressed(KEY_SPACE):
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var clicked_entity := _get_entity_at_position(entities_container.get_global_mouse_position())
		if clicked_entity != null:
			_set_focused_targets(clicked_entity, null)
			entity_actions_menu.hide()
			worker_action_dialog.hide()
			entity_config_dialog.show_for_entity(clicked_entity)
			get_viewport().set_input_as_handled()
			return

		var clicked_worker := _get_worker_at_position(workers_container.get_global_mouse_position())
		if clicked_worker != null:
			_set_focused_targets(null, clicked_worker)
			entity_actions_menu.hide()
			entity_config_dialog.hide()
			worker_action_dialog.show_for_worker(clicked_worker)
			get_viewport().set_input_as_handled()
			return

		_set_focused_targets(null, null)
		entity_actions_menu.hide()
		entity_config_dialog.hide()
		worker_action_dialog.hide()
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		var clicked_entity := _get_entity_at_position(entities_container.get_global_mouse_position())
		if clicked_entity == null:
			_set_focused_targets(null, null)
			entity_actions_menu.hide()
			return

		_context_entity = clicked_entity
		_set_focused_targets(clicked_entity, null)
		entity_actions_menu.popup_for_entity(clicked_entity, get_viewport().get_mouse_position())
		get_viewport().set_input_as_handled()


func _set_focused_targets(entity: Node2D, worker: WorkerAgent) -> void:
	_focused_entity = entity
	_focused_worker = worker
	for child in entities_container.get_children():
		if child.has_method("set_selection_state"):
			child.set_selection_state("none")

	for child in workers_container.get_children():
		if child.has_method("set_selection_state"):
			child.set_selection_state("none")

	if is_instance_valid(_focused_entity) and _focused_entity.has_method("set_selection_state"):
		_focused_entity.set_selection_state("focused")

	if is_instance_valid(_focused_worker) and _focused_worker.has_method("set_selection_state"):
		_focused_worker.set_selection_state("focused")


func _get_entity_at_position(world_position: Vector2) -> Node2D:
	var children := entities_container.get_children()
	for index in range(children.size() - 1, -1, -1):
		var child = children[index]
		if child is Node2D and child.has_method("contains_global_point") and child.contains_global_point(world_position):
			return child as Node2D
	return null


func _get_worker_at_position(world_position: Vector2) -> WorkerAgent:
	var children := workers_container.get_children()
	for index in range(children.size() - 1, -1, -1):
		var child = children[index]
		if child is WorkerAgent and child.contains_global_point(world_position):
			return child as WorkerAgent
	return null


func _on_popup_action_confirmed(action_id: String) -> void:
	if action_id != "destroy_entity" or not is_instance_valid(_context_entity):
		return

	var entities_to_remove: Array[Node2D] = [_context_entity]
	build_manager.remove_entities(entities_to_remove)
	_context_entity = null
	_set_focused_targets(null, null)


func _on_destroy_requested(entity: Node2D) -> void:
	_context_entity = entity
	var entity_id: String = entity.get_meta("entity_id", "")
	var entity_definition := EntityDatabase.get_entity(entity_id)
	var entity_name: String = str(entity_definition.get("nome", "Entidade"))
	confirmation_popup.show_confirmation(
		"destroy_entity",
		"Confirmar destruicao",
		"Deseja destruir %s?" % entity_name,
		"Destruir",
		"Cancelar"
	)


func _on_move_requested(entity: Node2D) -> void:
	_context_entity = null
	_set_focused_targets(null, null)
	build_manager.begin_move_entity(entity)


func _on_worker_action_selected(worker_id: String, action_id: String) -> void:
	_set_focused_targets(null, null)
	worker_action_requested.emit(worker_id, action_id)
