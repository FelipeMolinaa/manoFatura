extends Node

const SAVE_PATH := "user://dev_save.json"
const InventoryUtils = preload("res://scripts/data/inventory_utils.gd")

@export_node_path("Node") var build_manager_path: NodePath
@export_node_path("Node") var worker_manager_path: NodePath
@export_node_path("Node") var money_system_path: NodePath

var _is_loading := false

@onready var build_manager = get_node(build_manager_path)
@onready var worker_manager = get_node(worker_manager_path)
@onready var money_system: MoneySystem = get_node(money_system_path) as MoneySystem


func _ready() -> void:
	if build_manager.has_signal("entity_placed"):
		build_manager.entity_placed.connect(func(_entity_id: String, _cell: Vector2i) -> void:
			save_state()
		)
	if build_manager.has_signal("entity_sold"):
		build_manager.entity_sold.connect(func(_entity_id: String, _value: int) -> void:
			save_state()
		)
	if worker_manager.has_signal("workers_changed"):
		worker_manager.workers_changed.connect(save_state)
	money_system.money_changed.connect(func(_current_money: int, _delta: int) -> void:
		save_state()
	)


func _exit_tree() -> void:
	save_state()


func load_state() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false

	var state: Dictionary = parsed
	var entities_state: Array[Dictionary] = _decode_entities_state(state.get("entities", []))
	var workers_state: Array[Dictionary] = _decode_workers_state(state.get("workers", []))
	_is_loading = true
	build_manager.load_entities_state(entities_state)
	worker_manager.load_workers_state(workers_state)
	money_system.set_money_value(int(state.get("money", money_system.starting_money)))
	_is_loading = false
	return true


func save_state() -> void:
	if _is_loading:
		return

	var save_data := {
		"version": 1,
		"money": money_system.money,
		"entities": build_manager.get_entities_state(),
		"workers": _encode_workers_state(worker_manager.get_hired_workers_data()),
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(save_data, "\t"))


func delete_state() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)


func _encode_workers_state(workers_state: Array[Dictionary]) -> Array[Dictionary]:
	var encoded_state: Array[Dictionary] = []
	for worker_data in workers_state:
		var encoded := {
			"id": str(worker_data.get("id", "")),
			"nome": str(worker_data.get("nome", "")),
			"idade": int(worker_data.get("idade", 0)),
			"genero": str(worker_data.get("genero", "")),
			"velocidade": float(worker_data.get("velocidade", 0.0)),
			"forca": float(worker_data.get("forca", 0.0)),
		}

		var point_a = worker_data.get("point_a")
		if point_a is Vector2:
			encoded["point_a"] = {"x": point_a.x, "y": point_a.y}

		var point_b = worker_data.get("point_b")
		if point_b is Vector2:
			encoded["point_b"] = {"x": point_b.x, "y": point_b.y}

		var position = worker_data.get("position")
		if position is Vector2:
			encoded["position"] = {"x": position.x, "y": position.y}
		if worker_data.has("inventory"):
			encoded["inventory"] = _encode_inventory_state(worker_data.get("inventory", {}))
		if worker_data.has("point_configs"):
			encoded["point_configs"] = _duplicate_dictionary(worker_data.get("point_configs", {}))

		encoded_state.append(encoded)
	return encoded_state


func _decode_workers_state(workers_state: Array) -> Array[Dictionary]:
	var decoded_state: Array[Dictionary] = []
	for raw_worker_data in workers_state:
		if typeof(raw_worker_data) != TYPE_DICTIONARY:
			continue

		var worker_data: Dictionary = raw_worker_data
		var decoded := {
			"id": str(worker_data.get("id", "")),
			"nome": str(worker_data.get("nome", "")),
			"idade": int(worker_data.get("idade", 0)),
			"genero": str(worker_data.get("genero", "")),
			"velocidade": float(worker_data.get("velocidade", 0.0)),
			"forca": float(worker_data.get("forca", 0.0)),
		}

		if worker_data.has("point_a"):
			decoded["point_a"] = _dict_to_vector2(worker_data.get("point_a", {}))
		if worker_data.has("point_b"):
			decoded["point_b"] = _dict_to_vector2(worker_data.get("point_b", {}))
		if worker_data.has("position"):
			decoded["position"] = _dict_to_vector2(worker_data.get("position", {}))
		if worker_data.has("inventory"):
			decoded["inventory"] = _decode_inventory_state(worker_data.get("inventory", {}))
		if worker_data.has("point_configs"):
			decoded["point_configs"] = _duplicate_dictionary(worker_data.get("point_configs", {}))

		decoded_state.append(decoded)
	return decoded_state


func _decode_entities_state(raw_entities_state: Array) -> Array[Dictionary]:
	var decoded_state: Array[Dictionary] = []
	for raw_entity_state in raw_entities_state:
		if typeof(raw_entity_state) != TYPE_DICTIONARY:
			continue
		var entity_state: Dictionary = raw_entity_state
		var decoded: Dictionary = entity_state.duplicate(true)
		if decoded.has("inventory"):
			decoded["inventory"] = _decode_inventory_state(decoded.get("inventory", {}))
		decoded_state.append(decoded)
	return decoded_state


func _dict_to_vector2(raw_value: Variant) -> Vector2:
	if typeof(raw_value) != TYPE_DICTIONARY:
		return Vector2.ZERO

	var value: Dictionary = raw_value
	return Vector2(float(value.get("x", 0.0)), float(value.get("y", 0.0)))


func _encode_inventory_state(raw_inventory: Variant) -> Dictionary:
	var inventory: Dictionary = InventoryUtils.normalize_inventory(raw_inventory, [], -1.0)
	return inventory.duplicate(true)


func _decode_inventory_state(raw_inventory: Variant) -> Dictionary:
	if typeof(raw_inventory) != TYPE_DICTIONARY:
		return {}
	return (raw_inventory as Dictionary).duplicate(true)


func _duplicate_dictionary(raw_value: Variant) -> Dictionary:
	if typeof(raw_value) != TYPE_DICTIONARY:
		return {}
	return (raw_value as Dictionary).duplicate(true)
