class_name WorkerAgent
extends Node2D

const InventoryUtils = preload("res://scripts/data/inventory_utils.gd")

signal movement_target_reached(worker: Node2D, target_kind: String)
signal movement_blocked(worker: Node2D, blocked_by: Node2D)
signal movement_progressed(worker: Node2D)

const BODY_RADIUS := 11.0
const TARGET_KIND_RETREAT := "__retreat__"
const POSITION_HISTORY_MAX_SIZE := 24
const POSITION_HISTORY_MIN_DISTANCE := 6.0
const INVENTORY_SLOT_LABELS := ["Carga"]
const MAX_CARRY_WEIGHT := 5.0
const DEFAULT_TRANSFER_ITEM_ID := "aco"
const POINT_ACTION_PICKUP := "pickup"
const POINT_ACTION_DROPOFF := "dropoff"
const QUANTITY_MODE_AMOUNT := "amount"
const QUANTITY_MODE_PERCENT := "percent"

var worker_id := ""
var worker_name := "Funcionario"
var worker_age := 0
var worker_gender := ""
var point_a: Vector2
var point_b: Vector2
var has_point_a := false
var has_point_b := false
var speed := 80.0
var strength := 1.0
var inventory_data := InventoryUtils.make_inventory(INVENTORY_SLOT_LABELS, MAX_CARRY_WEIGHT)
var point_configs: Dictionary = {}

var _selection_state := "none"
var _current_path: Array[Vector2] = []
var _current_target_kind := ""
var _patrol_target_kind := ""
var _simulation_paused := false
var _blocked_signal_cooldown := 0.0
var _collision_pause_remaining := 0.0
var _position_history: Array[Vector2] = []
var _resume_target_kind := ""


func _ready() -> void:
	add_to_group("workers")
	_record_position_history(true)


func _process(delta: float) -> void:
	if _simulation_paused:
		return

	if _collision_pause_remaining > 0.0:
		_collision_pause_remaining = maxf(0.0, _collision_pause_remaining - delta)
		return

	_blocked_signal_cooldown = maxf(0.0, _blocked_signal_cooldown - delta)
	if _current_path.is_empty():
		return

	var next_point := _current_path[0]
	var distance_to_next := global_position.distance_to(next_point)
	var travel_distance := speed * delta
	var proposed_position := next_point if distance_to_next <= travel_distance else global_position.move_toward(next_point, travel_distance)

	var blocking_worker := _get_overlapping_worker(proposed_position)
	if blocking_worker != null:
		if _blocked_signal_cooldown <= 0.0:
			_blocked_signal_cooldown = 0.2
			movement_blocked.emit(self, blocking_worker)
		return

	if distance_to_next <= travel_distance:
		global_position = proposed_position
		_record_position_history()
		movement_progressed.emit(self)
		_current_path.remove_at(0)
		queue_redraw()
		if _current_path.is_empty():
			var reached_target_kind := _current_target_kind
			_current_target_kind = ""
			movement_target_reached.emit(self, reached_target_kind)
		return

	global_position = proposed_position
	_record_position_history()
	movement_progressed.emit(self)
	queue_redraw()


func configure_from_data(worker_data: Dictionary) -> void:
	worker_id = worker_data.get("id", "")
	worker_name = worker_data.get("nome", "Funcionario")
	worker_age = int(worker_data.get("idade", 0))
	worker_gender = worker_data.get("genero", "")
	speed = float(worker_data.get("velocidade", 80.0))
	strength = float(worker_data.get("forca", 1.0))

	var maybe_point_a = worker_data.get("point_a")
	has_point_a = maybe_point_a is Vector2
	if has_point_a:
		point_a = maybe_point_a

	var maybe_point_b = worker_data.get("point_b")
	has_point_b = maybe_point_b is Vector2
	if has_point_b:
		point_b = maybe_point_b

	if worker_data.has("position") and worker_data["position"] is Vector2:
		global_position = worker_data["position"]

	inventory_data = InventoryUtils.normalize_inventory(
		worker_data.get("inventory", {}),
		INVENTORY_SLOT_LABELS,
		MAX_CARRY_WEIGHT
	)
	point_configs = _normalize_point_configs(worker_data.get("point_configs", {}))

	_position_history.clear()
	_record_position_history(true)
	queue_redraw()


func set_selection_state(value: String) -> void:
	if _selection_state == value:
		return
	_selection_state = value
	queue_redraw()


func set_position_and_stop(world_position: Vector2) -> void:
	global_position = world_position
	clear_path()
	_position_history.clear()
	_record_position_history(true)
	movement_progressed.emit(self)
	queue_redraw()


func set_point(point_kind: String, world_position: Vector2) -> void:
	if point_kind == "point_a":
		point_a = world_position
		has_point_a = true
	elif point_kind == "point_b":
		point_b = world_position
		has_point_b = true

	queue_redraw()


func clear_path() -> void:
	_current_path.clear()
	_current_target_kind = ""
	_resume_target_kind = ""


func set_navigation_path(path_points: Array[Vector2], target_kind: String) -> void:
	_current_path = path_points.duplicate()
	_current_target_kind = target_kind
	_blocked_signal_cooldown = 0.0
	_resume_target_kind = ""


func begin_patrol_to(point_kind: String, path_points: Array[Vector2]) -> void:
	_patrol_target_kind = point_kind
	set_navigation_path(path_points, point_kind)


func begin_retreat(path_points: Array[Vector2], resume_target_kind: String) -> void:
	_current_path = path_points.duplicate()
	_current_target_kind = TARGET_KIND_RETREAT
	_resume_target_kind = resume_target_kind
	_blocked_signal_cooldown = 0.0


func can_patrol() -> bool:
	return has_point_a and has_point_b


func get_next_patrol_target_kind() -> String:
	if _current_target_kind == "point_a":
		return "point_b"
	if _current_target_kind == "point_b":
		return "point_a"
	if _patrol_target_kind == "point_a":
		return "point_b"
	if _patrol_target_kind == "point_b":
		return "point_a"
	return "point_a"


func get_target_position(point_kind: String) -> Vector2:
	return point_a if point_kind == "point_a" else point_b


func contains_global_point(world_position: Vector2) -> bool:
	return get_global_bounds().has_point(world_position)


func get_global_bounds() -> Rect2:
	return Rect2(global_position - Vector2(BODY_RADIUS, BODY_RADIUS), Vector2.ONE * BODY_RADIUS * 2.0)


func set_simulation_paused(paused: bool) -> void:
	_simulation_paused = paused


func pause_for(duration: float) -> void:
	_collision_pause_remaining = maxf(_collision_pause_remaining, duration)


func get_current_target_kind() -> String:
	return _current_target_kind


func has_navigation_target() -> bool:
	return not _current_target_kind.is_empty()


func has_resume_target_kind() -> bool:
	return not _resume_target_kind.is_empty()


func get_movement_direction() -> Vector2:
	if _current_path.is_empty():
		return Vector2.ZERO
	return (Vector2(_current_path[0]) - global_position).normalized()


func get_resume_target_kind() -> String:
	return _resume_target_kind


func get_position_history() -> Array[Vector2]:
	return _position_history.duplicate()


func is_retreating() -> bool:
	return _current_target_kind == TARGET_KIND_RETREAT


func get_inventory_data() -> Dictionary:
	return InventoryUtils.duplicate_inventory(inventory_data)


func get_inventory_total_weight() -> float:
	return InventoryUtils.get_total_weight(inventory_data)


func get_max_carry_weight() -> float:
	return MAX_CARRY_WEIGHT


func get_point_config(point_kind: String) -> Dictionary:
	if not point_configs.has(point_kind):
		point_configs[point_kind] = _make_default_point_config(point_kind)
	return (point_configs[point_kind] as Dictionary).duplicate(true)


func set_point_config(point_kind: String, config: Dictionary) -> void:
	if point_kind != "point_a" and point_kind != "point_b":
		return
	point_configs[point_kind] = _normalize_point_config(config, point_kind)


func add_item(item_id: String, amount: int) -> int:
	var added_amount := InventoryUtils.add_item(inventory_data, item_id, amount)
	if added_amount > 0:
		queue_redraw()
	return added_amount


func remove_item(item_id: String, amount: int) -> int:
	var removed_amount := InventoryUtils.remove_item(inventory_data, item_id, amount)
	if removed_amount > 0:
		queue_redraw()
	return removed_amount


func get_carried_item_id() -> String:
	return InventoryUtils.get_first_item_id(inventory_data)


func get_carried_item_amount(item_id: String) -> int:
	return InventoryUtils.get_item_amount(inventory_data, item_id)


func get_addable_item_amount(item_id: String, requested_amount: int) -> int:
	return InventoryUtils.get_addable_amount(inventory_data, item_id, requested_amount)


func _get_overlapping_worker(target_position: Vector2) -> WorkerAgent:
	var target_bounds := Rect2(target_position - Vector2(BODY_RADIUS, BODY_RADIUS), Vector2.ONE * BODY_RADIUS * 2.0)
	for node in get_tree().get_nodes_in_group("workers"):
		var other_worker := node as WorkerAgent
		if other_worker == null or other_worker == self:
			continue
		if target_bounds.intersects(other_worker.get_global_bounds()):
			return other_worker
	return null


func _record_position_history(force := false) -> void:
	if _position_history.is_empty():
		_position_history.append(global_position)
		return

	if not force and _position_history[-1].distance_to(global_position) < POSITION_HISTORY_MIN_DISTANCE:
		return

	_position_history.append(global_position)
	while _position_history.size() > POSITION_HISTORY_MAX_SIZE:
		_position_history.remove_at(0)


func to_data() -> Dictionary:
	return {
		"id": worker_id,
		"nome": worker_name,
		"idade": worker_age,
		"genero": worker_gender,
		"velocidade": speed,
		"forca": strength,
		"point_a": point_a if has_point_a else null,
		"point_b": point_b if has_point_b else null,
		"position": global_position,
		"inventory": InventoryUtils.duplicate_inventory(inventory_data),
		"point_configs": point_configs.duplicate(true),
	}


func _normalize_point_configs(raw_configs: Variant) -> Dictionary:
	var configs: Dictionary = raw_configs if raw_configs is Dictionary else {}
	return {
		"point_a": _normalize_point_config(configs.get("point_a", {}), "point_a"),
		"point_b": _normalize_point_config(configs.get("point_b", {}), "point_b"),
	}


func _normalize_point_config(raw_config: Variant, point_kind: String) -> Dictionary:
	var config: Dictionary = raw_config if raw_config is Dictionary else {}
	return {
		"action": str(config.get("action", POINT_ACTION_PICKUP if point_kind == "point_a" else POINT_ACTION_DROPOFF)),
		"quantity_mode": str(config.get("quantity_mode", QUANTITY_MODE_AMOUNT)),
		"quantity_value": maxf(float(config.get("quantity_value", 1.0)), 0.0),
		"item_id": str(config.get("item_id", DEFAULT_TRANSFER_ITEM_ID)),
	}


func _make_default_point_config(point_kind: String) -> Dictionary:
	return _normalize_point_config({}, point_kind)


func _draw() -> void:
	var body_color := Color("f8fafc")
	var border_color := Color("0f172a")
	var accent_color := Color("22c55e")

	draw_circle(Vector2.ZERO, BODY_RADIUS, body_color)
	draw_arc(Vector2.ZERO, BODY_RADIUS, 0.0, TAU, 24, border_color, 2.0)

	if _selection_state != "none":
		draw_circle(Vector2.ZERO, BODY_RADIUS + 6.0, Color(0.15, 0.75, 0.95, 0.15))
		draw_arc(Vector2.ZERO, BODY_RADIUS + 6.0, 0.0, TAU, 24, Color("38bdf8"), 2.0)

	if has_point_a:
		draw_circle(to_local(point_a), 4.0, Color("38bdf8"))

	if has_point_b:
		draw_circle(to_local(point_b), 4.0, Color("f97316"))

	if has_point_a and has_point_b:
		draw_line(to_local(point_a), to_local(point_b), Color(1, 1, 1, 0.15), 1.0)

	if not _current_path.is_empty():
		var previous_point := Vector2.ZERO
		for point in _current_path:
			var local_point := to_local(point)
			draw_line(previous_point, local_point, accent_color, 2.0)
			previous_point = local_point

	var font := ThemeDB.fallback_font
	if font == null:
		return

	draw_string(font, Vector2(-22, -18), worker_name, HORIZONTAL_ALIGNMENT_LEFT, 120.0, 12, Color("f8fafc"))
	draw_string(font, Vector2(-18, 28), "A", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("38bdf8"))
	draw_string(font, Vector2(8, 28), "B", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("f97316"))
