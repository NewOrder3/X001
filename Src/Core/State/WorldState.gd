class_name WorldState
extends RefCounted

## Serializable exploration state. Definitions hold map geometry and encounter content.

var current_region_id: StringName = &""
var discovered_region_ids: Array[StringName] = []
var consumed_encounter_keys: Array[StringName] = []
var exploration_revision: int = 0


func initialize(starting_region_id: StringName) -> void:
	current_region_id = starting_region_id
	discovered_region_ids.clear()
	consumed_encounter_keys.clear()
	exploration_revision = 0
	mark_discovered(starting_region_id)


func is_discovered(region_id: StringName) -> bool:
	return discovered_region_ids.has(region_id)


func mark_discovered(region_id: StringName) -> void:
	if region_id != &"" and not discovered_region_ids.has(region_id):
		discovered_region_ids.append(region_id)


func is_encounter_consumed(key: StringName) -> bool:
	return consumed_encounter_keys.has(key)


func mark_encounter_consumed(key: StringName) -> void:
	if key != &"" and not consumed_encounter_keys.has(key):
		consumed_encounter_keys.append(key)


func to_save_data() -> Dictionary:
	var discovered_ids: Array[String] = []
	for region_id: StringName in discovered_region_ids:
		discovered_ids.append(String(region_id))
	var consumed_keys: Array[String] = []
	for key: StringName in consumed_encounter_keys:
		consumed_keys.append(String(key))
	return {
		"current_region_id": String(current_region_id),
		"discovered_region_ids": discovered_ids,
		"consumed_encounter_keys": consumed_keys,
		"exploration_revision": exploration_revision,
	}


func load_from_save_data(data: Dictionary) -> bool:
	if data.is_empty():
		return true
	var raw_current_region_id: Variant = data.get("current_region_id")
	var raw_discovered_ids: Variant = data.get("discovered_region_ids")
	var raw_consumed_keys: Variant = data.get("consumed_encounter_keys")
	var raw_revision: Variant = data.get("exploration_revision", 0)
	if typeof(raw_current_region_id) != TYPE_STRING or not raw_discovered_ids is Array or not raw_consumed_keys is Array:
		return false
	if (typeof(raw_revision) != TYPE_INT and typeof(raw_revision) != TYPE_FLOAT) or float(raw_revision) != floor(float(raw_revision)) or int(raw_revision) < 0:
		return false
	var loaded_discovered_ids: Array[StringName] = []
	for raw_id: Variant in raw_discovered_ids:
		if typeof(raw_id) != TYPE_STRING or String(raw_id).is_empty():
			return false
		var region_id: StringName = StringName(raw_id)
		if loaded_discovered_ids.has(region_id):
			return false
		loaded_discovered_ids.append(region_id)
	var loaded_consumed_keys: Array[StringName] = []
	for raw_key: Variant in raw_consumed_keys:
		if typeof(raw_key) != TYPE_STRING or String(raw_key).is_empty():
			return false
		var key: StringName = StringName(raw_key)
		if loaded_consumed_keys.has(key):
			return false
		loaded_consumed_keys.append(key)
	current_region_id = StringName(raw_current_region_id)
	discovered_region_ids = loaded_discovered_ids
	consumed_encounter_keys = loaded_consumed_keys
	exploration_revision = int(raw_revision)
	return true
