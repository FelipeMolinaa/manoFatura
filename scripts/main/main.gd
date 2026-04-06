extends Node2D

const MODE_CAMERA := "Camera"
const MODE_BUILD := "Construir"

@onready var build_hud: Control = $CanvasLayer/BuildHUD
@onready var build_manager: Node = $BuildManager
@onready var money_system: MoneySystem = $MoneySystem
@onready var entity_interaction_controller: Node = $EntityInteractionController
@onready var worker_manager: Node = $WorkerManager
@onready var save_state_manager = $SaveStateManager
@onready var grid_overlay: Node2D = $World/GridOverlay
@onready var entities_container: Node2D = $World/Entities
@onready var workers_dialog = $CanvasLayer/WorkersDialog
@onready var confirmation_popup = $CanvasLayer/ConfirmationPopup
@onready var entity_config_dialog = $CanvasLayer/EntityConfigDialog

var current_mode := MODE_CAMERA
var _pending_fire_worker_id := ""
var _reopen_workers_dialog_on_action_finish := false


func _ready() -> void:
	build_hud.mode_selected.connect(_on_mode_selected)
	build_hud.build_selected.connect(_on_build_selected)
	build_hud.workers_requested.connect(_on_workers_requested)
	build_manager.building_selected.connect(_on_building_selected)
	grid_overlay.marker_requested.connect(_on_grid_marker_requested)
	money_system.money_changed.connect(_on_money_changed)
	entity_interaction_controller.worker_action_requested.connect(_on_worker_action_requested)
	worker_manager.workers_changed.connect(_refresh_workers_dialog)
	worker_manager.world_action_started.connect(_on_worker_world_action_started)
	worker_manager.world_action_finished.connect(_on_worker_world_action_finished)
	workers_dialog.hire_requested.connect(_on_worker_hire_requested)
	workers_dialog.worker_action_requested.connect(_on_worker_action_requested)
	workers_dialog.fire_requested.connect(_on_worker_fire_requested)
	confirmation_popup.action_confirmed.connect(_on_confirmation_action_confirmed)
	entity_config_dialog.confirmed.connect(_on_entity_config_confirmed)
	_set_mode(current_mode)
	save_state_manager.load_state()
	_on_building_selected(build_manager.get_selected_building_id())
	build_hud.set_money(money_system.money)
	_update_worker_preview()


func _on_mode_selected(mode: String) -> void:
	_set_mode(mode)


func _on_build_selected(entity_id: String) -> void:
	build_manager.select_building(entity_id)


func _on_workers_requested() -> void:
	_refresh_workers_dialog()
	workers_dialog.show_with_data(
		worker_manager.get_hired_workers_data(),
		worker_manager.get_available_profiles()
	)


func _on_building_selected(entity_id: String) -> void:
	build_hud.set_selected_building(entity_id)
	_update_entity_interaction_state()


func _on_money_changed(current_money: int, _delta: int) -> void:
	build_hud.set_money(current_money)


func _set_mode(mode: String) -> void:
	if mode != MODE_BUILD and worker_manager.has_pending_world_action():
		worker_manager.cancel_pending_world_action()

	current_mode = mode
	build_hud.set_mode(current_mode)

	if current_mode == MODE_BUILD:
		build_manager.set_build_mode_enabled(true)
		build_manager.cancel_pending_placement()
	else:
		build_manager.set_build_mode_enabled(false)
	_set_simulation_paused(current_mode == MODE_BUILD)
	_update_entity_interaction_state()
	_update_worker_preview()


func _unhandled_input(event: InputEvent) -> void:
	if not worker_manager.has_pending_world_action():
		return

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		worker_manager.cancel_pending_world_action()
		get_viewport().set_input_as_handled()


func _refresh_workers_dialog() -> void:
	if not workers_dialog.visible:
		return
	workers_dialog.show_with_data(
		worker_manager.get_hired_workers_data(),
		worker_manager.get_available_profiles()
	)


func _on_worker_hire_requested(profile_id: String) -> void:
	if worker_manager.hire_worker(profile_id):
		_refresh_workers_dialog()


func _on_worker_action_requested(worker_id: String, action_id: String) -> void:
	_set_mode(MODE_BUILD)
	build_manager.cancel_pending_placement()
	if worker_manager.start_world_action(worker_id, action_id):
		workers_dialog.hide()
		_update_entity_interaction_state()
		_update_worker_preview()


func _on_worker_fire_requested(worker_id: String) -> void:
	var worker: WorkerAgent = worker_manager.get_worker_by_id(worker_id)
	if worker == null:
		return

	_pending_fire_worker_id = worker_id
	confirmation_popup.show_confirmation(
		"fire_worker",
		"Confirmar demissao",
		"Deseja demitir %s?" % worker.worker_name,
		"Demitir",
		"Cancelar"
	)


func _on_worker_world_action_started(_action_id: String, _worker_name: String) -> void:
	build_hud.set_status_text(worker_manager.get_action_hint())
	_update_entity_interaction_state()
	_update_worker_preview()


func _on_worker_world_action_finished() -> void:
	build_hud.set_status_text("")
	_update_entity_interaction_state()
	_update_worker_preview()
	if _reopen_workers_dialog_on_action_finish:
		_reopen_workers_dialog_on_action_finish = false
		_open_workers_dialog()


func _on_confirmation_action_confirmed(action_id: String) -> void:
	if action_id != "fire_worker":
		return
	worker_manager.fire_worker(_pending_fire_worker_id)
	_pending_fire_worker_id = ""
	_refresh_workers_dialog()


func _on_entity_config_confirmed() -> void:
	save_state_manager.save_state()


func _open_workers_dialog() -> void:
	_refresh_workers_dialog()
	workers_dialog.show_with_data(
		worker_manager.get_hired_workers_data(),
		worker_manager.get_available_profiles()
	)


func _update_entity_interaction_state() -> void:
	entity_interaction_controller.set_active(
		current_mode == MODE_BUILD
		and not build_manager.has_pending_placement()
		and not worker_manager.has_pending_world_action()
	)


func _update_worker_preview() -> void:
	if current_mode == MODE_BUILD and worker_manager.has_pending_world_action():
		grid_overlay.show_marker_preview(worker_manager.get_preview_label(), worker_manager.get_preview_color())
		return
	grid_overlay.clear_marker_preview()


func _on_grid_marker_requested(cell: Vector2i) -> void:
	if not worker_manager.has_pending_world_action():
		return

	if worker_manager.apply_world_action(grid_overlay.get_cell_center_world_position(cell)):
		_reopen_workers_dialog_on_action_finish = true
		get_viewport().set_input_as_handled()


func _set_simulation_paused(paused: bool) -> void:
	worker_manager.set_simulation_paused(paused)
	for child in entities_container.get_children():
		if child.has_method("set_simulation_paused"):
			child.set_simulation_paused(paused)
