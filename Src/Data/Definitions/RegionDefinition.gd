class_name RegionDefinition
extends RefCounted

## Immutable map content. Coordinates use axial hex q/r values.

var id: StringName
var display_name: String
var description: String
var coordinate: Vector2i
var is_starting_region: bool
var encounter_ids: Array[StringName]


func _init(
	new_id: StringName,
	new_display_name: String,
	new_description: String,
	new_coordinate: Vector2i,
	new_is_starting_region: bool,
	new_encounter_ids: Array[StringName],
) -> void:
	id = new_id
	display_name = new_display_name
	description = new_description
	coordinate = new_coordinate
	is_starting_region = new_is_starting_region
	encounter_ids = new_encounter_ids.duplicate()
