extends PopupMenu

signal destroy_requested(entity: Node2D)
signal move_requested(entity: Node2D)

const ACTION_DESTROY := 1
const ACTION_MOVE := 2

var _target_entity: Node2D


func _ready() -> void:
	clear()
	add_item("Destruir", ACTION_DESTROY)
	add_item("Mover", ACTION_MOVE)
	id_pressed.connect(_on_id_pressed)


func popup_for_entity(entity: Node2D, viewport_position: Vector2) -> void:
	_target_entity = entity
	popup(Rect2i(Vector2i(viewport_position), Vector2i(1, 1)))


func _on_id_pressed(action_id: int) -> void:
	if not is_instance_valid(_target_entity):
		return

	if action_id == ACTION_DESTROY:
		destroy_requested.emit(_target_entity)
	elif action_id == ACTION_MOVE:
		move_requested.emit(_target_entity)
