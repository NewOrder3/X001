class_name ProgressionState
extends RefCounted

## Serializable raft growth runtime state. ProgressionSystem owns gameplay mutation.

var raft_level: int = 1


func to_save_data() -> Dictionary:
	return {
		"raft_level": raft_level,
	}


func load_from_save_data(data: Dictionary) -> bool:
	if data.is_empty():
		raft_level = 1
		return true
	var raw_raft_level: Variant = data.get("raft_level")
	if typeof(raw_raft_level) != TYPE_INT and typeof(raw_raft_level) != TYPE_FLOAT:
		return false
	var raft_level_value: float = float(raw_raft_level)
	if raft_level_value < 1.0 or raft_level_value != floor(raft_level_value):
		return false
	raft_level = int(raft_level_value)
	return true
