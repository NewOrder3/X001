class_name BuildingDefinition
extends RefCounted

## Immutable static content data shared by every placed building instance.

var id: StringName
var display_name: String
var description: String
var footprint: Vector2i
var build_cost: Dictionary[StringName, int]


func _init(
	new_id: StringName,
	new_display_name: String,
	new_description: String,
	new_footprint: Vector2i,
	new_build_cost: Dictionary[StringName, int] = {},
) -> void:
	id = new_id
	display_name = new_display_name
	description = new_description
	footprint = new_footprint
	build_cost = new_build_cost.duplicate()
