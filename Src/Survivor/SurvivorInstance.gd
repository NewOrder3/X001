class_name SurvivorInstance
extends RefCounted

## Serializable runtime state for one owned survivor; it never owns a View node.

var instance_id: StringName
var survivor_id: StringName
var level: int
var is_assigned: bool
var assigned_building_instance_id: StringName


func _init(
	new_instance_id: StringName,
	new_survivor_id: StringName,
	new_level: int = 1,
	new_is_assigned: bool = false,
	new_assigned_building_instance_id: StringName = &"",
) -> void:
	instance_id = new_instance_id
	survivor_id = new_survivor_id
	level = new_level
	is_assigned = new_is_assigned
	assigned_building_instance_id = new_assigned_building_instance_id
