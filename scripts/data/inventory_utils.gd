class_name InventoryUtils
extends RefCounted

const ItemDatabase = preload("res://scripts/data/item_database.gd")


static func make_empty_slot(label := "") -> Dictionary:
	return {
		"label": label,
		"item_id": "",
		"amount": 0,
	}


static func make_inventory(slot_labels: Array, max_weight: float = -1.0) -> Dictionary:
	var inventory: Dictionary = {
		"slot_count": slot_labels.size(),
		"max_weight": max_weight,
		"slots": [],
	}

	for raw_label in slot_labels:
		inventory["slots"].append(make_empty_slot(str(raw_label)))

	return inventory


static func normalize_inventory(raw_inventory: Variant, default_slot_labels: Array, default_max_weight: float = -1.0, default_max_amount: int = -1, force_slot_count: int = -1) -> Dictionary:
	var inventory: Dictionary = raw_inventory if raw_inventory is Dictionary else {}
	var slot_labels: Array[String] = []
	for raw_label in default_slot_labels:
		slot_labels.append(str(raw_label))

	var slot_count: int = maxi(int(inventory.get("slot_count", slot_labels.size())), slot_labels.size())
	if force_slot_count >= 0:
		slot_count = force_slot_count
		if slot_labels.size() > slot_count:
			slot_labels.resize(slot_count)
	while slot_labels.size() < slot_count:
		slot_labels.append("Slot %d" % (slot_labels.size() + 1))

	var raw_slots: Array = inventory.get("slots", [])
	var normalized_slots: Array[Dictionary] = []

	for index in range(slot_count):
		var raw_slot: Dictionary = raw_slots[index] if index < raw_slots.size() and raw_slots[index] is Dictionary else {}
		var label: String = str(raw_slot.get("label", slot_labels[index]))
		normalized_slots.append({
			"label": label,
			"item_id": str(raw_slot.get("item_id", "")),
			"amount": maxi(int(raw_slot.get("amount", 0)), 0),
		})

	var max_weight: float = float(inventory.get("max_weight", default_max_weight))
	if max_weight <= 0.0 and default_max_weight > 0.0:
		max_weight = default_max_weight

	var max_amount: int = int(inventory.get("max_amount", default_max_amount))
	if max_amount <= 0 and default_max_amount > 0:
		max_amount = default_max_amount

	var normalized_inventory: Dictionary = {
		"slot_count": slot_count,
		"max_weight": max_weight,
		"max_amount": max_amount,
		"slots": normalized_slots,
	}
	_clamp_total_amount(normalized_inventory)
	return normalized_inventory


static func duplicate_inventory(inventory: Dictionary) -> Dictionary:
	return inventory.duplicate(true)


static func get_total_amount(inventory: Dictionary) -> int:
	var total := 0
	for raw_slot in inventory.get("slots", []):
		if raw_slot is Dictionary:
			total += maxi(int(raw_slot.get("amount", 0)), 0)
	return total


static func get_total_weight(inventory: Dictionary) -> float:
	var total := 0.0
	for raw_slot in inventory.get("slots", []):
		if raw_slot is not Dictionary:
			continue

		var slot: Dictionary = raw_slot
		var item_id: String = str(slot.get("item_id", ""))
		var amount: int = maxi(int(slot.get("amount", 0)), 0)
		if item_id.is_empty() or amount <= 0:
			continue

		var item_definition: Dictionary = ItemDatabase.get_item(item_id)
		total += float(item_definition.get("peso", 0.0)) * amount
	return total


static func get_item_amount(inventory: Dictionary, item_id: String) -> int:
	if item_id.is_empty():
		return 0

	var total := 0
	for raw_slot in inventory.get("slots", []):
		if raw_slot is not Dictionary:
			continue

		var slot: Dictionary = raw_slot
		if str(slot.get("item_id", "")) == item_id:
			total += maxi(int(slot.get("amount", 0)), 0)
	return total


static func get_first_item_id(inventory: Dictionary) -> String:
	for raw_slot in inventory.get("slots", []):
		if raw_slot is not Dictionary:
			continue

		var slot: Dictionary = raw_slot
		var item_id: String = str(slot.get("item_id", ""))
		if not item_id.is_empty() and int(slot.get("amount", 0)) > 0:
			return item_id
	return ""


static func get_addable_amount(inventory: Dictionary, item_id: String, requested_amount: int) -> int:
	if item_id.is_empty() or requested_amount <= 0:
		return 0
	if not _has_existing_or_empty_slot(inventory, item_id):
		return 0

	var max_amount: int = int(inventory.get("max_amount", -1))
	if max_amount > 0:
		var available_amount: int = maxi(max_amount - get_total_amount(inventory), 0)
		requested_amount = mini(requested_amount, available_amount)
		if requested_amount <= 0:
			return 0

	var max_weight: float = float(inventory.get("max_weight", -1.0))
	if max_weight <= 0.0:
		return requested_amount

	var item_definition: Dictionary = ItemDatabase.get_item(item_id)
	var item_weight: float = float(item_definition.get("peso", 0.0))
	if item_weight <= 0.0:
		return requested_amount

	var available_weight: float = maxf(max_weight - get_total_weight(inventory), 0.0)
	return mini(requested_amount, int(floor(available_weight / item_weight)))


static func add_item(inventory: Dictionary, item_id: String, requested_amount: int) -> int:
	var addable_amount: int = get_addable_amount(inventory, item_id, requested_amount)
	if addable_amount <= 0:
		return 0

	var slots: Array = inventory.get("slots", [])
	for raw_slot in slots:
		if raw_slot is not Dictionary:
			continue

		var slot: Dictionary = raw_slot
		if str(slot.get("item_id", "")) == item_id:
			slot["amount"] = int(slot.get("amount", 0)) + addable_amount
			return addable_amount

	for raw_slot in slots:
		if raw_slot is not Dictionary:
			continue

		var slot: Dictionary = raw_slot
		if str(slot.get("item_id", "")).is_empty() or int(slot.get("amount", 0)) <= 0:
			slot["item_id"] = item_id
			slot["amount"] = addable_amount
			return addable_amount

	return 0


static func remove_item(inventory: Dictionary, item_id: String, requested_amount: int) -> int:
	if item_id.is_empty() or requested_amount <= 0:
		return 0

	var remaining := requested_amount
	var removed := 0
	for raw_slot in inventory.get("slots", []):
		if raw_slot is not Dictionary or remaining <= 0:
			continue

		var slot: Dictionary = raw_slot
		if str(slot.get("item_id", "")) != item_id:
			continue

		var current_amount: int = maxi(int(slot.get("amount", 0)), 0)
		var amount_to_remove: int = mini(current_amount, remaining)
		if amount_to_remove <= 0:
			continue

		var next_amount: int = current_amount - amount_to_remove
		slot["amount"] = next_amount
		if next_amount <= 0:
			slot["item_id"] = ""
		remaining -= amount_to_remove
		removed += amount_to_remove

	return removed


static func _has_existing_or_empty_slot(inventory: Dictionary, item_id: String) -> bool:
	for raw_slot in inventory.get("slots", []):
		if raw_slot is not Dictionary:
			continue

		var slot: Dictionary = raw_slot
		var slot_item_id: String = str(slot.get("item_id", ""))
		var slot_amount: int = int(slot.get("amount", 0))
		if slot_item_id == item_id:
			return true
		if slot_item_id.is_empty() or slot_amount <= 0:
			return true
	return false


static func _clamp_total_amount(inventory: Dictionary) -> void:
	var max_amount: int = int(inventory.get("max_amount", -1))
	if max_amount <= 0:
		return

	var remaining: int = max_amount
	for raw_slot in inventory.get("slots", []):
		if raw_slot is not Dictionary:
			continue

		var slot: Dictionary = raw_slot
		var slot_amount: int = maxi(int(slot.get("amount", 0)), 0)
		if remaining <= 0:
			slot["amount"] = 0
			slot["item_id"] = ""
			continue

		if slot_amount <= remaining:
			remaining -= slot_amount
			continue

		slot["amount"] = remaining
		remaining = 0
