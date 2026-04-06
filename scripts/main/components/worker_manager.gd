extends Node

const WORKER_SCENE := preload("res://scenes/entities/worker.tscn")

const NAV_CELL_SIZE := 16
const WORKER_RADIUS := 12.0
const COLLISION_WAIT_TIME := 0.10
const FOLLOW_WAIT_TIME := 0.5
const SIDE_COLLISION_RECALCULATE_THRESHOLD := 4
const FRONTAL_FORCE_ONE_RECALCULATE_THRESHOLD := 4
const FRONTAL_FORCE_BOTH_RECALCULATE_THRESHOLD := 7
const FRONTAL_RETREAT_THRESHOLD := 10
const WORKER_STUCK_RETREAT_THRESHOLD := 12
const WORKER_STUCK_REPOSITION_TIME_MS := 5000
const AVAILABLE_WORKERS := [
	{
		"id": "anne",
		"nome": "Anne",
		"idade": 23,
		"genero": "Feminino",
		"velocidade": 88.0,
		"forca": 2.0,
	},
	{
		"id": "felipe",
		"nome": "Felipe",
		"idade": 24,
		"genero": "Masculino",
		"velocidade": 76.0,
		"forca": 4.0,
	},
	{
		"id": "bia",
		"nome": "Beatriz",
		"idade": 30,
		"genero": "Feminino",
		"velocidade": 94.0,
		"forca": 1.0,
	},
]

signal workers_changed
signal world_action_started(action_id: String, worker_name: String)
signal world_action_finished

@export_node_path("Node2D") var entities_container_path: NodePath
@export_node_path("Node2D") var workers_container_path: NodePath
@export_node_path("Node2D") var grid_overlay_path: NodePath
@export_node_path("Node") var build_manager_path: NodePath

var _pending_world_action := {}
var _simulation_paused := false
var _active_collision_pairs: Dictionary = {}
var _collision_pair_counts: Dictionary = {}
var _worker_stall_counts: Dictionary = {}
var _worker_blocked_since_ms: Dictionary = {}

@onready var entities_container: Node2D = get_node(entities_container_path) as Node2D
@onready var workers_container: Node2D = get_node(workers_container_path) as Node2D
@onready var grid_overlay = get_node(grid_overlay_path)
@onready var build_manager = get_node(build_manager_path)


func _ready() -> void:
	randomize()
	if build_manager.has_signal("entity_placed"):
		build_manager.entity_placed.connect(func(_entity_id: String, _cell: Vector2i) -> void:
			_refresh_worker_paths()
		)
	if build_manager.has_signal("entity_sold"):
		build_manager.entity_sold.connect(func(_entity_id: String, _value: int) -> void:
			_refresh_worker_paths()
		)


func get_hired_workers_data() -> Array[Dictionary]:
	var hired_workers: Array[Dictionary] = []
	for worker in workers_container.get_children():
		if worker.has_method("to_data"):
			hired_workers.append(worker.to_data())
	return hired_workers


func get_available_profiles() -> Array[Dictionary]:
	var profiles: Array[Dictionary] = []
	for profile in AVAILABLE_WORKERS:
		if get_worker_by_id(profile["id"]) == null:
			profiles.append(profile.duplicate(true))
	return profiles


func hire_worker(profile_id: String) -> bool:
	if get_worker_by_id(profile_id) != null:
		return false

	var profile := _get_available_profile(profile_id)
	if profile.is_empty():
		return false

	var worker: WorkerAgent = WORKER_SCENE.instantiate() as WorkerAgent
	worker.configure_from_data(profile)
	worker.set_simulation_paused(_simulation_paused)
	worker.set_position_and_stop(_find_spawn_position())
	worker.movement_target_reached.connect(_on_worker_target_reached)
	worker.movement_blocked.connect(_on_worker_movement_blocked)
	worker.movement_progressed.connect(_on_worker_progressed)
	workers_container.add_child(worker)
	workers_changed.emit()
	return true


func fire_worker(worker_id: String) -> void:
	var worker: WorkerAgent = get_worker_by_id(worker_id)
	if worker == null:
		return

	if _has_pending_action_for_worker(worker_id):
		cancel_pending_world_action()

	workers_container.remove_child(worker)
	worker.queue_free()
	_clear_collision_history_for_worker(worker_id)
	_clear_worker_stall_state(worker_id)
	_clear_worker_blocked_state(worker_id)
	workers_changed.emit()
	_refresh_worker_paths()


func load_workers_state(workers_state: Array[Dictionary]) -> void:
	clear_all_workers()
	for worker_data in workers_state:
		var worker: WorkerAgent = WORKER_SCENE.instantiate() as WorkerAgent
		worker.configure_from_data(worker_data)
		worker.set_simulation_paused(_simulation_paused)
		worker.movement_target_reached.connect(_on_worker_target_reached)
		worker.movement_blocked.connect(_on_worker_movement_blocked)
		worker.movement_progressed.connect(_on_worker_progressed)
		workers_container.add_child(worker)
	workers_changed.emit()
	_refresh_worker_paths()


func clear_all_workers() -> void:
	for child in workers_container.get_children():
		workers_container.remove_child(child)
		child.queue_free()
	_active_collision_pairs.clear()
	_collision_pair_counts.clear()
	_worker_stall_counts.clear()
	_worker_blocked_since_ms.clear()


func start_world_action(worker_id: String, action_id: String) -> bool:
	var worker: WorkerAgent = get_worker_by_id(worker_id)
	if worker == null:
		return false

	var mapped_action := action_id
	if action_id == "position":
		mapped_action = "position"

	_pending_world_action = {
		"worker_id": worker_id,
		"action_id": mapped_action,
	}
	world_action_started.emit(mapped_action, worker.worker_name)
	return true


func has_pending_world_action() -> bool:
	return not _pending_world_action.is_empty()


func set_simulation_paused(paused: bool) -> void:
	_simulation_paused = paused
	for child in workers_container.get_children():
		var worker := child as WorkerAgent
		if worker != null:
			worker.set_simulation_paused(paused)


func cancel_pending_world_action() -> void:
	if _pending_world_action.is_empty():
		return
	_pending_world_action.clear()
	world_action_finished.emit()


func apply_world_action(world_position: Vector2) -> bool:
	if _pending_world_action.is_empty():
		return false

	var worker: WorkerAgent = get_worker_by_id(_pending_world_action.get("worker_id", ""))
	if worker == null:
		cancel_pending_world_action()
		return false

	var cell: Vector2i = grid_overlay.get_cell_from_world_position(world_position)
	var snapped_position: Vector2 = grid_overlay.get_cell_center_world_position(cell)
	if not _point_is_walkable(snapped_position, worker):
		return false

	var action_id: String = _pending_world_action.get("action_id", "")
	if action_id == "position":
		worker.set_position_and_stop(snapped_position)
		_clear_worker_stall_state(worker.worker_id)
		_try_start_worker_patrol(worker)
	elif action_id == "point_a" or action_id == "point_b":
		worker.set_point(action_id, snapped_position)
		_clear_worker_stall_state(worker.worker_id)
		_try_start_worker_patrol(worker)

	_pending_world_action.clear()
	world_action_finished.emit()
	workers_changed.emit()
	return true


func get_worker_by_id(worker_id: String) -> WorkerAgent:
	for child in workers_container.get_children():
		var worker := child as WorkerAgent
		if worker != null and worker.worker_id == worker_id:
			return worker
	return null


func get_action_hint() -> String:
	if _pending_world_action.is_empty():
		return ""

	var worker: WorkerAgent = get_worker_by_id(_pending_world_action.get("worker_id", ""))
	if worker == null:
		return ""

	var action_id: String = _pending_world_action.get("action_id", "")
	if action_id == "position":
		return "Clique no mapa para posicionar %s." % worker.worker_name
	if action_id == "point_a":
		return "Clique no mapa para definir o Ponto A de %s." % worker.worker_name
	if action_id == "point_b":
		return "Clique no mapa para definir o Ponto B de %s." % worker.worker_name
	return ""


func get_preview_label() -> String:
	if _pending_world_action.is_empty():
		return ""

	var action_id: String = _pending_world_action.get("action_id", "")
	if action_id == "position":
		return "F"
	if action_id == "point_a":
		return "A"
	if action_id == "point_b":
		return "B"
	return ""


func get_preview_color() -> Color:
	if _pending_world_action.is_empty():
		return Color("f8fafc")

	var action_id: String = _pending_world_action.get("action_id", "")
	if action_id == "point_a":
		return Color("38bdf8")
	if action_id == "point_b":
		return Color("f97316")
	return Color("f8fafc")


func _has_pending_action_for_worker(worker_id: String) -> bool:
	return _pending_world_action.get("worker_id", "") == worker_id


func _get_available_profile(profile_id: String) -> Dictionary:
	for profile in AVAILABLE_WORKERS:
		if profile["id"] == profile_id:
			return profile.duplicate(true)
	return {}


func _find_spawn_position() -> Vector2:
	var world_rect: Rect2 = grid_overlay.get_world_rect()
	for y in range(0, int(world_rect.size.y), NAV_CELL_SIZE):
		for x in range(0, int(world_rect.size.x), NAV_CELL_SIZE):
			var candidate := Vector2(x + NAV_CELL_SIZE * 0.5, y + NAV_CELL_SIZE * 0.5)
			if _point_is_walkable(candidate, null):
				return candidate
	return Vector2(48, 48)


func _refresh_worker_paths() -> void:
	for worker in workers_container.get_children():
		_try_start_worker_patrol(worker)


func _try_start_worker_patrol(worker: WorkerAgent) -> void:
	if worker == null or not is_instance_valid(worker):
		return

	if worker.is_retreating():
		return

	if not worker.can_patrol():
		worker.clear_path()
		return

	var next_target_kind := worker.get_current_target_kind()
	if next_target_kind.is_empty():
		if worker.has_resume_target_kind():
			next_target_kind = worker.get_resume_target_kind()
		else:
			next_target_kind = _get_initial_patrol_target_kind(worker)

	_start_worker_patrol_to(worker, next_target_kind)


func _start_worker_patrol_to(worker: WorkerAgent, target_kind: String) -> bool:
	if worker == null or not is_instance_valid(worker):
		return false
	if target_kind.is_empty():
		return false

	var target_position := worker.get_target_position(target_kind)
	var path := _build_navigation_path(worker, worker.global_position, target_position)
	if path.is_empty():
		return false

	worker.begin_patrol_to(target_kind, path)
	return true


func _get_initial_patrol_target_kind(worker: WorkerAgent) -> String:
	var distance_to_a := worker.global_position.distance_to(worker.point_a)
	var distance_to_b := worker.global_position.distance_to(worker.point_b)
	if distance_to_a <= distance_to_b:
		return "point_a"
	return "point_b"


func _build_navigation_path(worker: WorkerAgent, from_position: Vector2, to_position: Vector2) -> Array[Vector2]:
	var astar := AStarGrid2D.new()
	var world_rect: Rect2 = grid_overlay.get_world_rect()
	var nav_columns := int(ceil(world_rect.size.x / float(NAV_CELL_SIZE)))
	var nav_rows := int(ceil(world_rect.size.y / float(NAV_CELL_SIZE)))
	astar.region = Rect2i(0, 0, nav_columns, nav_rows)
	astar.cell_size = Vector2(NAV_CELL_SIZE, NAV_CELL_SIZE)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ALWAYS
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.update()

	var obstacle_rects := _build_obstacle_rects(worker)
	for obstacle_rect in obstacle_rects:
		var start_cell := _world_to_nav_cell(obstacle_rect.position)
		var end_cell := _world_to_nav_cell(obstacle_rect.end)
		for y in range(start_cell.y, end_cell.y + 1):
			for x in range(start_cell.x, end_cell.x + 1):
				var nav_cell := Vector2i(x, y)
				if not astar.is_in_boundsv(nav_cell):
					continue
				astar.set_point_solid(nav_cell, true)

	var start_cell := _find_nearest_walkable_cell(astar, _world_to_nav_cell(from_position))
	var end_cell := _find_nearest_walkable_cell(astar, _world_to_nav_cell(to_position))
	if start_cell == Vector2i(-1, -1) or end_cell == Vector2i(-1, -1):
		return []

	var raw_path := astar.get_point_path(start_cell, end_cell)
	if raw_path.is_empty():
		return []

	var smoothed := _smooth_path(raw_path, obstacle_rects)
	if smoothed.is_empty():
		return []

	if smoothed[0].distance_to(from_position) <= WORKER_RADIUS * 1.5:
		smoothed.remove_at(0)

	if smoothed.is_empty() or smoothed[-1].distance_to(to_position) > 4.0:
		smoothed.append(to_position)

	return smoothed


func _build_obstacle_rects(excluded_worker: WorkerAgent) -> Array[Rect2]:
	var obstacle_rects: Array[Rect2] = []

	for entity in entities_container.get_children():
		if entity.has_method("get_global_bounds"):
			obstacle_rects.append(entity.get_global_bounds().grow(WORKER_RADIUS))

	for worker in workers_container.get_children():
		if worker == excluded_worker:
			continue
		obstacle_rects.append(worker.get_global_bounds().grow(2.0))

	return obstacle_rects


func _smooth_path(raw_path: PackedVector2Array, obstacle_rects: Array[Rect2]) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for point in raw_path:
		points.append(point)

	if points.size() <= 2:
		return points

	var smoothed: Array[Vector2] = [points[0]]
	var current_index := 0

	while current_index < points.size() - 1:
		var next_index := points.size() - 1
		while next_index > current_index + 1:
			if _segment_is_clear(points[current_index], points[next_index], obstacle_rects):
				break
			next_index -= 1
		smoothed.append(points[next_index])
		current_index = next_index

	return smoothed


func _segment_is_clear(from_point: Vector2, to_point: Vector2, obstacle_rects: Array[Rect2]) -> bool:
	for obstacle_rect in obstacle_rects:
		if _segment_intersects_rect(from_point, to_point, obstacle_rect):
			return false
	return true


func _segment_intersects_rect(from_point: Vector2, to_point: Vector2, obstacle_rect: Rect2) -> bool:
	if obstacle_rect.has_point(from_point) or obstacle_rect.has_point(to_point):
		return true

	var direction := to_point - from_point
	var t_min := 0.0
	var t_max := 1.0

	if is_zero_approx(direction.x):
		if from_point.x < obstacle_rect.position.x or from_point.x > obstacle_rect.end.x:
			return false
	else:
		var inverse_delta_x := 1.0 / direction.x
		var tx1 := (obstacle_rect.position.x - from_point.x) * inverse_delta_x
		var tx2 := (obstacle_rect.end.x - from_point.x) * inverse_delta_x
		t_min = maxf(t_min, minf(tx1, tx2))
		t_max = minf(t_max, maxf(tx1, tx2))
		if t_min > t_max:
			return false

	if is_zero_approx(direction.y):
		if from_point.y < obstacle_rect.position.y or from_point.y > obstacle_rect.end.y:
			return false
	else:
		var inverse_delta_y := 1.0 / direction.y
		var ty1 := (obstacle_rect.position.y - from_point.y) * inverse_delta_y
		var ty2 := (obstacle_rect.end.y - from_point.y) * inverse_delta_y
		t_min = maxf(t_min, minf(ty1, ty2))
		t_max = minf(t_max, maxf(ty1, ty2))
		if t_min > t_max:
			return false

	return true


func _point_is_walkable(world_position: Vector2, excluded_worker: WorkerAgent) -> bool:
	for obstacle_rect in _build_obstacle_rects(excluded_worker):
		if obstacle_rect.has_point(world_position):
			return false
	return grid_overlay.get_world_rect().has_point(world_position)


func _world_to_nav_cell(world_position: Vector2) -> Vector2i:
	return Vector2i(
		maxi(0, int(floor(world_position.x / float(NAV_CELL_SIZE)))),
		maxi(0, int(floor(world_position.y / float(NAV_CELL_SIZE))))
	)


func _find_nearest_walkable_cell(astar: AStarGrid2D, origin: Vector2i) -> Vector2i:
	if astar.is_in_boundsv(origin) and not astar.is_point_solid(origin):
		return origin

	for radius in range(1, 10):
		for y in range(origin.y - radius, origin.y + radius + 1):
			for x in range(origin.x - radius, origin.x + radius + 1):
				var candidate := Vector2i(x, y)
				if not astar.is_in_boundsv(candidate):
					continue
				if not astar.is_point_solid(candidate):
					return candidate

	return Vector2i(-1, -1)


func _on_worker_target_reached(worker: WorkerAgent, target_kind: String) -> void:
	_clear_collision_history_for_worker(worker.worker_id)
	_clear_worker_stall_state(worker.worker_id)
	if target_kind == WorkerAgent.TARGET_KIND_RETREAT:
		var resume_target_kind := worker.get_resume_target_kind()
		if not resume_target_kind.is_empty():
			_start_worker_patrol_to(worker, resume_target_kind)
		return

	var next_target_kind := "point_a"
	if target_kind == "point_a":
		next_target_kind = "point_b"
	elif target_kind == "point_b":
		next_target_kind = "point_a"
	_start_worker_patrol_to(worker, next_target_kind)


func _on_worker_movement_blocked(worker_node: Node2D, blocked_by_node: Node2D) -> void:
	if _simulation_paused:
		return

	var worker := worker_node as WorkerAgent
	var blocked_by := blocked_by_node as WorkerAgent
	if worker == null or blocked_by == null:
		return

	if _should_reposition_stuck_worker(worker):
		_reposition_stuck_worker(worker)
		return

	var pair_key := _make_collision_pair_key(worker.worker_id, blocked_by.worker_id)
	var worker_stall_count := _register_worker_stall(worker.worker_id)
	if worker_stall_count >= WORKER_STUCK_RETREAT_THRESHOLD:
		if _attempt_worker_stall_retreat(worker, blocked_by):
			_clear_collision_history_for_pair(pair_key)
			return
		if _attempt_worker_stall_retreat(blocked_by, worker):
			_clear_collision_history_for_pair(pair_key)
			return

	var collision_count := _register_collision_for_pair(pair_key)

	if not _is_frontal_collision(worker, blocked_by):
		worker.pause_for(FOLLOW_WAIT_TIME)
		if collision_count >= SIDE_COLLISION_RECALCULATE_THRESHOLD:
			_recalculate_current_route(worker)
		return

	if _active_collision_pairs.has(pair_key):
		return

	_active_collision_pairs[pair_key] = true
	worker.pause_for(COLLISION_WAIT_TIME)
	blocked_by.pause_for(COLLISION_WAIT_TIME)

	var worker_should_recalculate := randf() < 0.5
	var blocked_by_should_recalculate := randf() < 0.5
	if collision_count >= FRONTAL_FORCE_ONE_RECALCULATE_THRESHOLD and not worker_should_recalculate and not blocked_by_should_recalculate:
		if randf() < 0.5:
			worker_should_recalculate = true
		else:
			blocked_by_should_recalculate = true
	if collision_count >= FRONTAL_FORCE_BOTH_RECALCULATE_THRESHOLD:
		worker_should_recalculate = true
		blocked_by_should_recalculate = true
	get_tree().create_timer(COLLISION_WAIT_TIME).timeout.connect(func() -> void:
		_resolve_collision_pair(
			pair_key,
			worker.worker_id,
			blocked_by.worker_id,
			worker_should_recalculate,
			blocked_by_should_recalculate
		)
	)


func _resolve_collision_pair(
	pair_key: String,
	worker_id: String,
	blocked_by_id: String,
	worker_should_recalculate: bool,
	blocked_by_should_recalculate: bool
) -> void:
	_active_collision_pairs.erase(pair_key)

	if _simulation_paused:
		return

	var worker := get_worker_by_id(worker_id)
	var blocked_by := get_worker_by_id(blocked_by_id)
	if worker == null or blocked_by == null:
		return

	if worker.is_retreating() or blocked_by.is_retreating():
		return

	var collision_count := int(_collision_pair_counts.get(pair_key, 0))
	if collision_count >= FRONTAL_RETREAT_THRESHOLD and _attempt_deadlock_retreat(pair_key, worker, blocked_by):
		return

	if worker_should_recalculate:
		_recalculate_current_route(worker)
	if blocked_by_should_recalculate:
		_recalculate_current_route(blocked_by)


func _recalculate_current_route(worker: WorkerAgent) -> void:
	if worker == null or not is_instance_valid(worker):
		return
	if worker.is_retreating():
		return
	if not worker.has_navigation_target():
		return

	_start_worker_patrol_to(worker, worker.get_current_target_kind())


func _make_collision_pair_key(worker_a_id: String, worker_b_id: String) -> String:
	if worker_a_id < worker_b_id:
		return "%s|%s" % [worker_a_id, worker_b_id]
	return "%s|%s" % [worker_b_id, worker_a_id]


func _register_collision_for_pair(pair_key: String) -> int:
	var count := int(_collision_pair_counts.get(pair_key, 0)) + 1
	_collision_pair_counts[pair_key] = count
	return count


func _register_worker_stall(worker_id: String) -> int:
	var count := int(_worker_stall_counts.get(worker_id, 0)) + 1
	_worker_stall_counts[worker_id] = count
	return count


func _should_reposition_stuck_worker(worker: WorkerAgent) -> bool:
	if worker == null:
		return false

	var now_ms := Time.get_ticks_msec()
	if not _worker_blocked_since_ms.has(worker.worker_id):
		_worker_blocked_since_ms[worker.worker_id] = now_ms
		return false

	var blocked_since_ms := int(_worker_blocked_since_ms.get(worker.worker_id, now_ms))
	return now_ms - blocked_since_ms >= WORKER_STUCK_REPOSITION_TIME_MS


func _clear_collision_history_for_pair(pair_key: String) -> void:
	_collision_pair_counts.erase(pair_key)
	_active_collision_pairs.erase(pair_key)


func _clear_worker_stall_state(worker_id: String) -> void:
	_worker_stall_counts.erase(worker_id)


func _clear_worker_blocked_state(worker_id: String) -> void:
	_worker_blocked_since_ms.erase(worker_id)


func _clear_collision_history_for_worker(worker_id: String) -> void:
	var keys_to_remove: Array[String] = []
	for pair_key in _collision_pair_counts.keys():
		var key_text := str(pair_key)
		var ids := key_text.split("|")
		if ids.size() == 2 and (ids[0] == worker_id or ids[1] == worker_id):
			keys_to_remove.append(key_text)

	for pair_key in keys_to_remove:
		_clear_collision_history_for_pair(pair_key)


func _on_worker_progressed(worker_node: Node2D) -> void:
	var worker := worker_node as WorkerAgent
	if worker == null:
		return

	_clear_worker_stall_state(worker.worker_id)
	_clear_worker_blocked_state(worker.worker_id)
	_clear_collision_history_for_worker(worker.worker_id)


func _attempt_worker_stall_retreat(worker: WorkerAgent, blocked_by: WorkerAgent) -> bool:
	if worker == null or blocked_by == null:
		return false
	if worker.is_retreating() or not worker.has_navigation_target():
		return false

	var resume_target_kind := worker.get_current_target_kind()
	if resume_target_kind.is_empty():
		return false

	var retreat_path := _build_retreat_path(worker, blocked_by)
	if retreat_path.is_empty():
		return false

	worker.begin_retreat(retreat_path, resume_target_kind)
	_clear_worker_stall_state(worker.worker_id)
	_clear_worker_blocked_state(worker.worker_id)
	_clear_collision_history_for_worker(worker.worker_id)
	return true


func _attempt_deadlock_retreat(pair_key: String, worker: WorkerAgent, blocked_by: WorkerAgent) -> bool:
	var retreat_options: Array[Dictionary] = []
	var worker_retreat_path := _build_retreat_path(worker, blocked_by)
	if not worker_retreat_path.is_empty() and worker.has_navigation_target() and not worker.is_retreating():
		retreat_options.append({
			"worker": worker,
			"path": worker_retreat_path,
			"resume_target_kind": worker.get_current_target_kind(),
		})

	var blocked_by_retreat_path := _build_retreat_path(blocked_by, worker)
	if not blocked_by_retreat_path.is_empty() and blocked_by.has_navigation_target() and not blocked_by.is_retreating():
		retreat_options.append({
			"worker": blocked_by,
			"path": blocked_by_retreat_path,
			"resume_target_kind": blocked_by.get_current_target_kind(),
		})

	if retreat_options.is_empty():
		return false

	var selected_option: Dictionary = retreat_options[randi() % retreat_options.size()]
	var retreating_worker: WorkerAgent = selected_option.get("worker") as WorkerAgent
	var retreat_path: Array[Vector2] = []
	var retreat_path_variant = selected_option.get("path", [])
	for point in retreat_path_variant:
		retreat_path.append(point)
	var resume_target_kind := str(selected_option.get("resume_target_kind", ""))
	if retreating_worker == null or retreat_path.is_empty() or resume_target_kind.is_empty():
		return false

	retreating_worker.begin_retreat(retreat_path, resume_target_kind)
	_clear_worker_stall_state(retreating_worker.worker_id)
	_clear_worker_blocked_state(retreating_worker.worker_id)
	_clear_collision_history_for_pair(pair_key)
	return true


func _reposition_stuck_worker(worker: WorkerAgent) -> void:
	if worker == null or not is_instance_valid(worker):
		return

	var reposition_cell := _find_nearest_empty_worker_cell(worker)
	if reposition_cell == Vector2i(-1, -1):
		return

	var reposition_world_position: Vector2 = grid_overlay.get_cell_center_world_position(reposition_cell)
	worker.set_position_and_stop(reposition_world_position)
	_clear_worker_stall_state(worker.worker_id)
	_clear_worker_blocked_state(worker.worker_id)
	_clear_collision_history_for_worker(worker.worker_id)
	_try_start_worker_patrol(worker)


func _find_nearest_empty_worker_cell(worker: WorkerAgent) -> Vector2i:
	if worker == null:
		return Vector2i(-1, -1)

	var world_rect: Rect2 = grid_overlay.get_world_rect()
	var cell_origin_center: Vector2 = grid_overlay.get_cell_center_world_position(Vector2i.ZERO)
	var next_cell_center: Vector2 = grid_overlay.get_cell_center_world_position(Vector2i(1, 0))
	var cell_step := next_cell_center.x - cell_origin_center.x
	if is_zero_approx(cell_step):
		return Vector2i(-1, -1)

	var columns := int(round(world_rect.size.x / cell_step))
	var rows := int(round(world_rect.size.y / cell_step))
	var origin_cell: Vector2i = grid_overlay.get_cell_from_world_position(worker.global_position)
	var nearest_cell := Vector2i(-1, -1)
	var nearest_distance := INF

	for y in range(rows):
		for x in range(columns):
			var candidate_cell := Vector2i(x, y)
			if candidate_cell == origin_cell:
				continue

			var candidate_world_position: Vector2 = grid_overlay.get_cell_center_world_position(candidate_cell)
			if not _point_is_walkable(candidate_world_position, worker):
				continue

			var distance := origin_cell.distance_squared_to(candidate_cell)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_cell = candidate_cell

	return nearest_cell


func _build_retreat_path(worker: WorkerAgent, blocked_by: WorkerAgent) -> Array[Vector2]:
	var retreat_path: Array[Vector2] = []
	if worker == null or blocked_by == null:
		return retreat_path

	var position_history := worker.get_position_history()
	if position_history.size() < 2:
		return retreat_path

	var current_distance := worker.global_position.distance_to(blocked_by.global_position)
	for index in range(position_history.size() - 2, -1, -1):
		var history_position: Vector2 = position_history[index]
		if history_position.distance_to(worker.global_position) < WorkerAgent.POSITION_HISTORY_MIN_DISTANCE:
			continue

		var gained_distance := history_position.distance_to(blocked_by.global_position) - current_distance
		if gained_distance < WORKER_RADIUS * 1.5:
			continue
		if not _point_is_walkable(history_position, worker):
			continue

		retreat_path = _build_navigation_path(worker, worker.global_position, history_position)
		if not retreat_path.is_empty():
			return retreat_path

	retreat_path.clear()
	return retreat_path


func _is_frontal_collision(worker: WorkerAgent, blocked_by: WorkerAgent) -> bool:
	var worker_direction := worker.get_movement_direction()
	var blocked_direction := blocked_by.get_movement_direction()
	if worker_direction == Vector2.ZERO or blocked_direction == Vector2.ZERO:
		return false

	var direction_alignment := worker_direction.dot(blocked_direction)
	if direction_alignment > -0.35:
		return false

	var to_blocked := (blocked_by.global_position - worker.global_position).normalized()
	if to_blocked == Vector2.ZERO:
		return true

	var worker_facing_blocked := worker_direction.dot(to_blocked) > 0.35
	var blocked_facing_worker := blocked_direction.dot(-to_blocked) > 0.35
	return worker_facing_blocked and blocked_facing_worker
