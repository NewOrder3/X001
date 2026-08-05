class_name RecipeDefinition
extends RefCounted

## Immutable production recipe. A building opts in through its required capability tag.

var id: StringName
var display_name_key: StringName
var cycle_seconds: float
var input_items: Dictionary[StringName, int]
var output_items: Dictionary[StringName, int]
var required_capability_tag: StringName


func _init(
	new_id: StringName,
	new_display_name_key: StringName,
	new_cycle_seconds: float,
	new_input_items: Dictionary[StringName, int],
	new_output_items: Dictionary[StringName, int],
	new_required_capability_tag: StringName,
) -> void:
	id = new_id
	display_name_key = new_display_name_key
	cycle_seconds = new_cycle_seconds
	input_items = new_input_items.duplicate()
	output_items = new_output_items.duplicate()
	required_capability_tag = new_required_capability_tag


func get_display_name() -> String:
	return GameText.get_text(display_name_key)
