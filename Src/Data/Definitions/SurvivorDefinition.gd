class_name SurvivorDefinition
extends RefCounted

## Immutable card content shared by each unique owned survivor.

var id: StringName
var display_name_key: StringName
var description_key: StringName
var skill_id: StringName
var passive_id: StringName
var passive_value_per_level: float
var upgrade_cost: Dictionary[StringName, int]


func _init(
	new_id: StringName,
	new_display_name_key: StringName,
	new_description_key: StringName,
	new_skill_id: StringName,
	new_passive_id: StringName,
	new_passive_value_per_level: float,
	new_upgrade_cost: Dictionary[StringName, int],
) -> void:
	id = new_id
	display_name_key = new_display_name_key
	description_key = new_description_key
	skill_id = new_skill_id
	passive_id = new_passive_id
	passive_value_per_level = new_passive_value_per_level
	upgrade_cost = new_upgrade_cost.duplicate()


func get_display_name() -> String:
	return GameText.get_text(display_name_key)


func get_description() -> String:
	return GameText.get_text(description_key)
