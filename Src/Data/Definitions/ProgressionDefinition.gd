class_name ProgressionDefinition
extends RefCounted

## Immutable progression node: a raft level table or a data-driven unlock rule.

enum Kind {
	RAFT_LEVEL,
	UNLOCK,
}

var id: StringName
var kind: Kind
var raft_level: int
var raft_width: int
var raft_height: int
var upgrade_cost: Dictionary[StringName, int]
var unlock_id: StringName
var required_building_id: StringName
var required_raft_level: int


func _init(
	new_id: StringName,
	new_kind: Kind,
	new_raft_level: int = 0,
	new_raft_width: int = 0,
	new_raft_height: int = 0,
	new_upgrade_cost: Dictionary[StringName, int] = {},
	new_unlock_id: StringName = &"",
	new_required_building_id: StringName = &"",
	new_required_raft_level: int = 0,
) -> void:
	id = new_id
	kind = new_kind
	raft_level = new_raft_level
	raft_width = new_raft_width
	raft_height = new_raft_height
	upgrade_cost = new_upgrade_cost.duplicate()
	unlock_id = new_unlock_id
	required_building_id = new_required_building_id
	required_raft_level = new_required_raft_level


func is_raft_level() -> bool:
	return kind == Kind.RAFT_LEVEL


func is_unlock() -> bool:
	return kind == Kind.UNLOCK
