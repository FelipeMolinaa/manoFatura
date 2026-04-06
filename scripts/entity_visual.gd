extends Node2D

const TILE_SIZE := 32

@export var entity_name := "Entidade"
@export var entity_size_in_tiles := Vector2i(2, 2)
@export var entity_color := Color("38bdf8")
@export var is_infinite_source := false

var _selection_state := "none"
var _secondary_label := ""
var _simulation_paused := false


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var size := Vector2(entity_size_in_tiles * TILE_SIZE)
	var rect := Rect2(Vector2.ZERO, size)
	var fill_color := entity_color
	fill_color.a = 0.9
	var border_color := entity_color.lightened(0.2)
	var label_color := Color("e2e8f0")

	draw_rect(rect, fill_color, true)
	draw_rect(rect, border_color, false, 2.0)
	draw_line(Vector2(0, 0), size, Color(1, 1, 1, 0.12), 1.0)
	draw_line(Vector2(size.x, 0), Vector2(0, size.y), Color(1, 1, 1, 0.12), 1.0)

	if _selection_state != "none":
		var selection_color := Color("38bdf8")
		if _selection_state == "danger":
			selection_color = Color("f97316")
		var selection_fill := selection_color
		selection_fill.a = 0.1
		draw_rect(rect.grow(3.0), selection_fill, true)
		draw_rect(rect.grow(3.0), selection_color, false, 3.0)

	var font := ThemeDB.fallback_font
	if font != null:
		var font_size := 16
		var text_size := font.get_string_size(entity_name, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var text_position := Vector2(
			(size.x - text_size.x) * 0.5,
			(size.y + text_size.y) * 0.5 - 4.0
		)
		draw_string(font, text_position, entity_name, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, label_color)

		if is_infinite_source:
			draw_string(font, Vector2(10, 20), "INF", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("ecfeff"))

		if not _secondary_label.is_empty():
			draw_string(font, Vector2(10, size.y - 10), _secondary_label, HORIZONTAL_ALIGNMENT_LEFT, size.x - 20, 12, Color("cbd5e1"))


func set_selection_state(value: String) -> void:
	if _selection_state == value:
		return
	_selection_state = value
	queue_redraw()


func set_secondary_label(value: String) -> void:
	if _secondary_label == value:
		return
	_secondary_label = value
	queue_redraw()


func set_simulation_paused(paused: bool) -> void:
	_simulation_paused = paused


func contains_global_point(world_position: Vector2) -> bool:
	return get_global_bounds().has_point(world_position)


func get_global_bounds() -> Rect2:
	return Rect2(global_position, Vector2(entity_size_in_tiles * TILE_SIZE))
