class_name QuestState
extends RefCounted

## Serializable quest progress. QuestSystem owns all gameplay mutation.

var completed_quest_ids: Array[StringName] = []
var defeated_boss_ids: Array[StringName] = []
var used_item_counts: Dictionary[StringName, int] = {}


func to_save_data() -> Dictionary:
	return {
		"completed_quest_ids": _to_string_array(completed_quest_ids),
		"defeated_boss_ids": _to_string_array(defeated_boss_ids),
		"used_item_counts": _to_string_int_dictionary(used_item_counts),
	}


func load_from_save_data(data: Dictionary) -> bool:
	if data.is_empty():
		completed_quest_ids.clear()
		defeated_boss_ids.clear()
		used_item_counts.clear()
		return true
	var raw_completed: Variant = data.get("completed_quest_ids")
	var raw_defeated: Variant = data.get("defeated_boss_ids")
	var raw_used_items: Variant = data.get("used_item_counts")
	if not raw_completed is Array or not raw_defeated is Array or not raw_used_items is Dictionary:
		return false
	var completed: Array[StringName] = []
	var defeated: Array[StringName] = []
	var used_items: Dictionary[StringName, int] = {}
	for raw_id: Variant in raw_completed:
		if typeof(raw_id) != TYPE_STRING:
			return false
		var quest_id: StringName = StringName(raw_id)
		if not IdValidator.is_valid_id(quest_id) or not String(quest_id).begins_with("quest_") or completed.has(quest_id):
			return false
		completed.append(quest_id)
	for raw_id: Variant in raw_defeated:
		if typeof(raw_id) != TYPE_STRING:
			return false
		var boss_id: StringName = StringName(raw_id)
		if not IdValidator.is_valid_id(boss_id) or not String(boss_id).begins_with("boss_") or defeated.has(boss_id):
			return false
		defeated.append(boss_id)
	for raw_item_id: Variant in raw_used_items:
		if typeof(raw_item_id) != TYPE_STRING:
			return false
		var item_id: StringName = StringName(raw_item_id)
		var raw_amount: Variant = raw_used_items[raw_item_id]
		if not IdValidator.is_valid_id(item_id) or not String(item_id).begins_with("item_") or (typeof(raw_amount) != TYPE_INT and typeof(raw_amount) != TYPE_FLOAT) or float(raw_amount) != floor(float(raw_amount)) or int(raw_amount) <= 0:
			return false
		used_items[item_id] = int(raw_amount)
	completed_quest_ids = completed
	defeated_boss_ids = defeated
	used_item_counts = used_items
	return true


func _to_string_array(values: Array[StringName]) -> Array[String]:
	var result: Array[String] = []
	for value: StringName in values:
		result.append(String(value))
	return result


func _to_string_int_dictionary(values: Dictionary[StringName, int]) -> Dictionary[String, int]:
	var result: Dictionary[String, int] = {}
	for item_id: StringName in values:
		result[String(item_id)] = values[item_id]
	return result
