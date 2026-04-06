extends Node2D

const CELL_SIZE := 32
const GRID_COLUMNS := 80
const GRID_ROWS := 80

signal placement_requested(cell: Vector2i)
signal marker_requested(cell: Vector2i)

var block_input := false
var placement_enabled := false:
	set(value):
		if placement_enabled == value:
			return
		placement_enabled = value
		if not value:
			_has_hovered_cell = false
		queue_redraw()
var build_mode_enabled := false:
	set(value):
		if build_mode_enabled == value:
			return
		build_mode_enabled = value
		visible = value
		if not value:
			_has_hovered_cell = false
		queue_redraw()

var _has_hovered_cell := false
var _hovered_cell := Vector2i.ZERO
var _preview_size := Vector2i.ONE
var _preview_color := Color("38bdf8")
var _occupied_cells: Dictionary = {}
var _marker_preview_enabled := false
var _marker_preview_label := ""
var _marker_preview_color := Color("f8fafc")


func _ready() -> void:
	visible = build_mode_enabled
	set_process_unhandled_input(true)


func _unhandled_input(event: InputEvent) -> void:
	if not build_mode_enabled or block_input:
		return

	if Input.is_key_pressed(KEY_SPACE):
		return

	if event is InputEventMouseMotion:
		_update_hovered_cell(get_global_mouse_position())
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_update_hovered_cell(get_global_mouse_position())
		if _marker_preview_enabled:
			marker_requested.emit(_hovered_cell)
			return
		if not placement_enabled:
			return
		if _can_place_at(_hovered_cell):
			placement_requested.emit(_hovered_cell)


func set_build_preview(size_in_tiles: Vector2i, preview_color: Color) -> void:
	_preview_size = size_in_tiles
	_preview_color = preview_color
	queue_redraw()


func set_occupied_cells(cells: Array[Vector2i]) -> void:
	_occupied_cells.clear()
	for cell in cells:
		_occupied_cells[cell] = true
	queue_redraw()


func get_cell_world_position(cell: Vector2i) -> Vector2:
	return Vector2(cell * CELL_SIZE)


func is_area_free(cell: Vector2i, size_in_tiles: Vector2i) -> bool:
	return _is_rect_inside_grid(cell, size_in_tiles) and _is_cell_area_free(cell, size_in_tiles)


func get_world_rect() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(GRID_COLUMNS * CELL_SIZE, GRID_ROWS * CELL_SIZE))


func get_cell_from_world_position(world_position: Vector2) -> Vector2i:
	return _mouse_to_cell(world_position)


func get_cell_center_world_position(cell: Vector2i) -> Vector2:
	return Vector2(cell * CELL_SIZE) + Vector2.ONE * (CELL_SIZE * 0.5)


func show_marker_preview(label_text: String, preview_color: Color) -> void:
	_marker_preview_enabled = true
	_marker_preview_label = label_text
	_marker_preview_color = preview_color
	_update_hovered_cell(get_global_mouse_position())
	queue_redraw()


func clear_marker_preview() -> void:
	if not _marker_preview_enabled:
		return
	_marker_preview_enabled = false
	_marker_preview_label = ""
	queue_redraw()


func _draw() -> void:
	if not build_mode_enabled:
		return

	var grid_size := Vector2(GRID_COLUMNS * CELL_SIZE, GRID_ROWS * CELL_SIZE)
	var grid_color := Color(0.75, 0.8, 0.9, 0.16)

	for column in range(GRID_COLUMNS + 1):
		var x := float(column * CELL_SIZE)
		draw_line(Vector2(x, 0), Vector2(x, grid_size.y), grid_color, 1.0)

	for row in range(GRID_ROWS + 1):
		var y := float(row * CELL_SIZE)
		draw_line(Vector2(0, y), Vector2(grid_size.x, y), grid_color, 1.0)

	if placement_enabled and _has_hovered_cell:
		var preview_rect := _rect_for_area(_hovered_cell, _preview_size)
		var can_place := _can_place_at(_hovered_cell)
		var fill_color := _preview_color
		fill_color.a = 0.26 if can_place else 0.18
		var border_color := _preview_color.lightened(0.25) if can_place else Color("ef4444")

		draw_rect(preview_rect, fill_color, true)
		draw_rect(preview_rect, border_color, false, 2.0)

		for y in range(_preview_size.y):
			for x in range(_preview_size.x):
				var cell := _hovered_cell + Vector2i(x, y)
				if _occupied_cells.has(cell):
					draw_rect(_cell_rect(cell), Color(0.95, 0.25, 0.25, 0.22), true)
					draw_rect(_cell_rect(cell), Color(0.95, 0.35, 0.35, 0.6), false, 2.0)

	if _marker_preview_enabled and _has_hovered_cell:
		var marker_rect := _cell_rect(_hovered_cell)
		var marker_fill := _marker_preview_color
		marker_fill.a = 0.22
		draw_rect(marker_rect, marker_fill, true)
		draw_rect(marker_rect, _marker_preview_color, false, 2.0)

		var font := ThemeDB.fallback_font
		if font != null and not _marker_preview_label.is_empty():
			var font_size := 20
			var text_size := font.get_string_size(_marker_preview_label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
			var text_position := marker_rect.position + Vector2(
				(marker_rect.size.x - text_size.x) * 0.5,
				(marker_rect.size.y + text_size.y) * 0.5 - 3.0
			)
			draw_string(font, text_position, _marker_preview_label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, _marker_preview_color)


func _update_hovered_cell(mouse_position: Vector2) -> void:
	var cell := _mouse_to_cell(mouse_position)
	if _has_hovered_cell and cell == _hovered_cell:
		return
	_hovered_cell = cell
	_has_hovered_cell = true
	queue_redraw()


func _mouse_to_cell(mouse_position: Vector2) -> Vector2i:
	var local_position := to_local(mouse_position)
	return Vector2i(
		clampi(int(floor(local_position.x / CELL_SIZE)), 0, GRID_COLUMNS - 1),
		clampi(int(floor(local_position.y / CELL_SIZE)), 0, GRID_ROWS - 1)
	)


func _can_place_at(cell: Vector2i) -> bool:
	return _is_rect_inside_grid(cell, _preview_size) and _is_cell_area_free(cell, _preview_size)


func _is_rect_inside_grid(cell: Vector2i, size_in_tiles: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x + size_in_tiles.x <= GRID_COLUMNS and cell.y + size_in_tiles.y <= GRID_ROWS


func _is_cell_area_free(cell: Vector2i, size_in_tiles: Vector2i) -> bool:
	for y in range(size_in_tiles.y):
		for x in range(size_in_tiles.x):
			if _occupied_cells.has(cell + Vector2i(x, y)):
				return false
	return true


func _rect_for_area(cell: Vector2i, size_in_tiles: Vector2i) -> Rect2:
	return Rect2(Vector2(cell * CELL_SIZE), Vector2(size_in_tiles * CELL_SIZE))


func _cell_rect(cell: Vector2i) -> Rect2:
	return Rect2(Vector2(cell * CELL_SIZE), Vector2(CELL_SIZE, CELL_SIZE))
