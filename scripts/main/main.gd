extends Node2D

const MODE_CAMERA := "Camera"
const MODE_BUILD := "Construir"

@onready var build_hud: Control = $CanvasLayer/BuildHUD
@onready var build_manager: Node = $BuildManager
@onready var money_system: MoneySystem = $MoneySystem
@onready var entity_interaction_controller: Node = $EntityInteractionController

var current_mode := MODE_CAMERA


func _ready() -> void:
	build_hud.mode_selected.connect(_on_mode_selected)
	build_hud.build_selected.connect(_on_build_selected)
	build_manager.building_selected.connect(_on_building_selected)
	money_system.money_changed.connect(_on_money_changed)
	_set_mode(current_mode)
	_on_building_selected(build_manager.get_selected_building_id())
	build_hud.set_money(money_system.money)


func _on_mode_selected(mode: String) -> void:
	_set_mode(mode)


func _on_build_selected(entity_id: String) -> void:
	build_manager.select_building(entity_id)


func _on_building_selected(entity_id: String) -> void:
	build_hud.set_selected_building(entity_id)
	entity_interaction_controller.set_active(current_mode == MODE_BUILD and not build_manager.has_pending_placement())


func _on_money_changed(current_money: int, _delta: int) -> void:
	build_hud.set_money(current_money)


func _set_mode(mode: String) -> void:
	current_mode = mode
	build_hud.set_mode(current_mode)

	if current_mode == MODE_BUILD:
		build_manager.set_build_mode_enabled(true)
		build_manager.cancel_pending_placement()
	else:
		build_manager.set_build_mode_enabled(false)
		entity_interaction_controller.set_active(false)
