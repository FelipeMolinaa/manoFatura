extends Node

const ZOOM_STEP := 0.1
const MIN_ZOOM := 0.5
const MAX_ZOOM := 2.5

@export_node_path("Camera2D") var camera_path: NodePath
@export_node_path("Node2D") var grid_overlay_path: NodePath

var is_panning := false

@onready var camera_2d: Camera2D = get_node(camera_path) as Camera2D
@onready var grid_overlay: Node2D = get_node(grid_overlay_path) as Node2D


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


func _apply_zoom(delta: float) -> void:
	var next_zoom := clampf(camera_2d.zoom.x + delta, MIN_ZOOM, MAX_ZOOM)
	camera_2d.zoom = Vector2(next_zoom, next_zoom)
