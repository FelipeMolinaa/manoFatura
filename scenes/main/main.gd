extends Node2D

@onready var camera: Camera2D = $Camera2D
@onready var grid_overlay: Node2D = $GridOverlay

func _ready() -> void:
	EventBus.build_mode_changed.connect(_on_build_mode_changed)

func _on_build_mode_changed(active: bool, entity_id: String) -> void:
	pass

func _input(event: InputEvent) -> void:
	pass
