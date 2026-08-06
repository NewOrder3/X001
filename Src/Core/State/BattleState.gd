class_name BattleState
extends RefCounted

## Serializable runtime battle state. BattleSystem is its sole mutator.

enum Status {
	IDLE,
	ACTIVE,
	COMPLETED,
}

var status: Status = Status.IDLE
var boss_id: StringName = &""
var boss_current_health: int = 0
var party_health: Dictionary[StringName, int] = {}
var skill_cooldowns: Dictionary[StringName, int] = {}
var turn_number: int = 0
var did_win: bool = false
var settlement_applied: bool = false


func to_save_data() -> Dictionary:
	return {
		"status": int(status),
		"boss_id": String(boss_id),
		"boss_current_health": boss_current_health,
		"party_health": _to_string_int_dictionary(party_health),
		"skill_cooldowns": _to_string_int_dictionary(skill_cooldowns),
		"turn_number": turn_number,
		"did_win": did_win,
		"settlement_applied": settlement_applied,
	}


func load_from_save_data(data: Dictionary) -> bool:
	if data.is_empty():
		return true
	var raw_status: Variant = data.get("status")
	var raw_boss_id: Variant = data.get("boss_id")
	var raw_health: Variant = data.get("boss_current_health")
	var raw_party_health: Variant = data.get("party_health")
	var raw_cooldowns: Variant = data.get("skill_cooldowns")
	var raw_turn: Variant = data.get("turn_number")
	var raw_did_win: Variant = data.get("did_win")
	var raw_settled: Variant = data.get("settlement_applied")
	if (typeof(raw_status) != TYPE_INT and typeof(raw_status) != TYPE_FLOAT) or typeof(raw_boss_id) != TYPE_STRING or (typeof(raw_health) != TYPE_INT and typeof(raw_health) != TYPE_FLOAT) or not raw_party_health is Dictionary or not raw_cooldowns is Dictionary or (typeof(raw_turn) != TYPE_INT and typeof(raw_turn) != TYPE_FLOAT) or typeof(raw_did_win) != TYPE_BOOL or typeof(raw_settled) != TYPE_BOOL:
		return false
	var loaded_status: int = int(raw_status)
	var loaded_health: int = int(raw_health)
	var loaded_turn: int = int(raw_turn)
	if float(raw_status) != float(loaded_status) or float(raw_health) != float(loaded_health) or float(raw_turn) != float(loaded_turn) or loaded_status < Status.IDLE or loaded_status > Status.COMPLETED or loaded_health < 0 or loaded_turn < 0:
		return false
	var loaded_party_health: Dictionary[StringName, int] = _read_survivor_int_dictionary(raw_party_health)
	var loaded_cooldowns: Dictionary[StringName, int] = _read_survivor_int_dictionary(raw_cooldowns)
	if loaded_party_health.size() != raw_party_health.size() or loaded_cooldowns.size() != raw_cooldowns.size():
		return false
	var loaded_boss_id: StringName = StringName(raw_boss_id)
	if loaded_status == Status.IDLE:
		clear()
		return true
	if not IdValidator.is_valid_id(loaded_boss_id) or not String(loaded_boss_id).begins_with("boss_") or loaded_party_health.is_empty():
		return false
	status = loaded_status
	boss_id = loaded_boss_id
	boss_current_health = loaded_health
	party_health = loaded_party_health
	skill_cooldowns = loaded_cooldowns
	turn_number = loaded_turn
	did_win = raw_did_win
	settlement_applied = raw_settled
	return true


func clear() -> void:
	status = Status.IDLE
	boss_id = &""
	boss_current_health = 0
	party_health.clear()
	skill_cooldowns.clear()
	turn_number = 0
	did_win = false
	settlement_applied = false


func is_active() -> bool:
	return status == Status.ACTIVE


func _to_string_int_dictionary(values: Dictionary[StringName, int]) -> Dictionary[String, int]:
	var result: Dictionary[String, int] = {}
	for id: StringName in values:
		result[String(id)] = values[id]
	return result


func _read_survivor_int_dictionary(raw_values: Dictionary) -> Dictionary[StringName, int]:
	var result: Dictionary[StringName, int] = {}
	for raw_id: Variant in raw_values:
		var raw_value: Variant = raw_values[raw_id]
		if typeof(raw_id) != TYPE_STRING or (typeof(raw_value) != TYPE_INT and typeof(raw_value) != TYPE_FLOAT):
			return {}
		var survivor_id: StringName = StringName(raw_id)
		var value: int = int(raw_value)
		if not IdValidator.is_valid_id(survivor_id) or not String(survivor_id).begins_with("survivor_") or float(raw_value) != float(value) or value < 0:
			return {}
		result[survivor_id] = value
	return result
