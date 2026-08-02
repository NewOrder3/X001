class_name InventorySystem
extends RefCounted

## Applies inventory changes after validating IDs and quantities against loaded content.

signal item_amount_changed(item_id: StringName, new_amount: int)

var _data_registry: DataRegistry


func _init(new_data_registry: DataRegistry) -> void:
	_data_registry = new_data_registry


func get_amount(state: InventoryState, item_id: StringName) -> int:
	if state == null:
		return 0
	return state.item_amounts.get(item_id, 0)


func add(state: InventoryState, item_id: StringName, amount: int) -> bool:
	if not _is_valid_change(state, item_id, amount):
		return false
	var new_amount: int = get_amount(state, item_id) + amount
	state.item_amounts[item_id] = new_amount
	item_amount_changed.emit(item_id, new_amount)
	return true


func can_afford(state: InventoryState, costs: Dictionary[StringName, int]) -> bool:
	if state == null:
		return false
	for item_id: StringName in costs:
		var amount: int = costs[item_id]
		if amount <= 0 or get_amount(state, item_id) < amount:
			return false
	return true


func spend_cost(state: InventoryState, costs: Dictionary[StringName, int]) -> bool:
	if not can_afford(state, costs):
		return false
	for item_id: StringName in costs:
		var new_amount: int = get_amount(state, item_id) - costs[item_id]
		state.item_amounts[item_id] = new_amount
		item_amount_changed.emit(item_id, new_amount)
	return true


func _is_valid_change(state: InventoryState, item_id: StringName, amount: int) -> bool:
	return state != null and amount > 0 and _data_registry != null and _data_registry.has_item(item_id)
