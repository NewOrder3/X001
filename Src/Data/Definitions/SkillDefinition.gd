class_name SkillDefinition
extends RefCounted

## Immutable skill description used by survivor cards. Battle resolution is introduced in S6.

var id: StringName
var display_name_key: StringName
var description_key: StringName


func _init(
	new_id: StringName,
	new_display_name_key: StringName,
	new_description_key: StringName,
) -> void:
	id = new_id
	display_name_key = new_display_name_key
	description_key = new_description_key


func get_display_name() -> String:
	return GameText.get_text(display_name_key)


func get_description() -> String:
	return GameText.get_text(description_key)
