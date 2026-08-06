class_name QuestState
extends RefCounted

## Serializable quest progress. QuestSystem owns all gameplay mutation.

var completed_quest_ids: Array[StringName] = []
var defeated_boss_ids: Array[StringName] = []


func to_save_data() -> Dictionary:
	return {
		"completed_quest_ids": _to_string_array(completed_quest_ids),
		"defeated_boss_ids": _to_string_array(defeated_boss_ids),
	}


func load_from_save_data(data: Dictionary) -> bool:
	if data.is_empty():
		completed_quest_ids.clear()
		defeated_boss_ids.clear()
		return true
	var raw_completed: Variant = data.get("completed_quest_ids")
	var raw_defeated: Variant = data.get("defeated_boss_ids")
	if not raw_completed is Array or not raw_defeated is Array:
		return false
	var completed: Array[StringName] = []
	var defeated: Array[StringName] = []
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
	completed_quest_ids = completed
	defeated_boss_ids = defeated
	return true


func _to_string_array(values: Array[StringName]) -> Array[String]:
	var result: Array[String] = []
	for value: StringName in values:
		result.append(String(value))
	return result
