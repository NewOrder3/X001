class_name RegionDefinition
extends RefCounted

## Immutable map content. Coordinates use axial hex q/r values.

var id: StringName
var display_name_key: StringName
var description_key: StringName
var coordinate: Vector2i
var is_starting_region: bool
var encounter_ids: Array[StringName]
var display_name_override: String


func _init(
	new_id: StringName,
	new_display_name_key: StringName,
	new_description_key: StringName,
	new_coordinate: Vector2i,
	new_is_starting_region: bool,
	new_encounter_ids: Array[StringName],
	new_display_name_override: String = "",
) -> void:
	id = new_id
	display_name_key = new_display_name_key
	description_key = new_description_key
	coordinate = new_coordinate
	is_starting_region = new_is_starting_region
	encounter_ids = new_encounter_ids.duplicate()
	display_name_override = new_display_name_override


func get_display_name() -> String:
	if not display_name_override.is_empty():
		return display_name_override
	return GameText.get_text(display_name_key)


func get_description() -> String:
	return GameText.get_text(description_key)
