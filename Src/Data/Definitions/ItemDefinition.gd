class_name ItemDefinition
extends RefCounted

## Immutable static content data shared by every item instance/reference.

var id: StringName
var display_name: String
var description: String


func _init(new_id: StringName, new_display_name: String, new_description: String) -> void:
	id = new_id
	display_name = new_display_name
	description = new_description
