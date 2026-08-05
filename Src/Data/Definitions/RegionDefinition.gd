class_name RegionDefinition
extends RefCounted

## Immutable map content. Coordinates use axial hex q/r values.

var id: StringName
var display_name_key: StringName
var description_key: StringName
var coordinate: Vector2i
var is_starting_region: bool
var encounter_ids: Array[StringName]


func _init(
	new_id: StringName,
	new_display_name_key: StringName,
	new_description_key: StringName,
	new_coordinate: Vector2i,
	new_is_starting_region: bool,
	new_encounter_ids: Array[StringName],
) -> void:
	id = new_id
	display_name_key = new_display_name_key
	description_key = new_description_key
	coordinate = new_coordinate
	is_starting_region = new_is_starting_region
	encounter_ids = new_encounter_ids.duplicate()


func get_display_name() -> String:
	return GameText.get_text(display_name_key)


func get_description() -> String:
	return GameText.get_text(description_key)
