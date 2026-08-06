class_name SurvivorState
extends RefCounted

## Serializable roster and lineup state. SurvivorSystem owns all mutations.

const MAX_LINEUP_SIZE: int = 3

var survivors: Dictionary[StringName, SurvivorInstance] = {}
var pending_recruitment_ids: Array[StringName] = []
var lineup_ids: Array[StringName] = []


func to_save_data() -> Dictionary:
	var survivor_data: Array[Dictionary] = []
	var survivor_ids: Array[StringName] = []
	for survivor_id: StringName in survivors:
		survivor_ids.append(survivor_id)
	survivor_ids.sort()
	for survivor_id: StringName in survivor_ids:
		var instance: SurvivorInstance = survivors[survivor_id]
		survivor_data.append({
			"instance_id": String(instance.instance_id),
			"survivor_id": String(instance.survivor_id),
			"level": instance.level,
		})
	return {
		"survivors": survivor_data,
		"pending_recruitment_ids": _to_string_array(pending_recruitment_ids),
		"lineup_ids": _to_string_array(lineup_ids),
	}


func load_from_save_data(data: Dictionary) -> bool:
	if data.is_empty():
		return true
	var raw_survivors: Variant = data.get("survivors", [])
	var raw_pending_ids: Variant = data.get("pending_recruitment_ids", [])
	var raw_lineup_ids: Variant = data.get("lineup_ids", [])
	if not raw_survivors is Array or not raw_pending_ids is Array or not raw_lineup_ids is Array:
		return false

	var loaded_survivors: Dictionary[StringName, SurvivorInstance] = {}
	for raw_entry: Variant in raw_survivors:
		if not raw_entry is Dictionary:
			return false
		var raw_instance_id: Variant = raw_entry.get("instance_id")
		var raw_survivor_id: Variant = raw_entry.get("survivor_id")
		var raw_level: Variant = raw_entry.get("level")
		if typeof(raw_instance_id) != TYPE_STRING or typeof(raw_survivor_id) != TYPE_STRING:
			return false
		if typeof(raw_level) != TYPE_INT and typeof(raw_level) != TYPE_FLOAT:
			return false
		var survivor_id: StringName = StringName(raw_survivor_id)
		var level: int = int(raw_level)
		if float(raw_level) != float(level) or not IdValidator.is_valid_id(survivor_id) or not String(survivor_id).begins_with("survivor_") or level < 1 or level > 10 or loaded_survivors.has(survivor_id):
			return false
		loaded_survivors[survivor_id] = SurvivorInstance.new(StringName(raw_instance_id), survivor_id, level)

	var loaded_pending_ids: Array[StringName] = _read_unique_survivor_ids(raw_pending_ids)
	var loaded_lineup_ids: Array[StringName] = _read_unique_survivor_ids(raw_lineup_ids)
	if loaded_pending_ids.size() != raw_pending_ids.size() or loaded_lineup_ids.size() != raw_lineup_ids.size() or loaded_lineup_ids.size() > MAX_LINEUP_SIZE:
		return false
	for survivor_id: StringName in loaded_lineup_ids:
		if not loaded_survivors.has(survivor_id):
			return false
	for survivor_id: StringName in loaded_pending_ids:
		if loaded_survivors.has(survivor_id):
			return false

	survivors = loaded_survivors
	pending_recruitment_ids = loaded_pending_ids
	lineup_ids = loaded_lineup_ids
	return true


func _read_unique_survivor_ids(raw_ids: Array) -> Array[StringName]:
	var ids: Array[StringName] = []
	for raw_id: Variant in raw_ids:
		if typeof(raw_id) != TYPE_STRING:
			return []
		var survivor_id: StringName = StringName(raw_id)
		if not IdValidator.is_valid_id(survivor_id) or not String(survivor_id).begins_with("survivor_") or ids.has(survivor_id):
			return []
		ids.append(survivor_id)
	return ids


func _to_string_array(ids: Array[StringName]) -> Array[String]:
	var values: Array[String] = []
	for survivor_id: StringName in ids:
		values.append(String(survivor_id))
	return values
