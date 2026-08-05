class_name ItemDefinition
extends RefCounted

## Immutable static content data shared by every item instance/reference.

var id: StringName
var display_name_key: StringName
var description_key: StringName
var base_capacity: int
var supply_restore_amount: float


func _init(
	new_id: StringName,
	new_display_name_key: StringName,
	new_description_key: StringName,
	new_base_capacity: int = 99,
	new_supply_restore_amount: float = 0.0,
) -> void:
	id = new_id
	display_name_key = new_display_name_key
	description_key = new_description_key
	base_capacity = new_base_capacity
	supply_restore_amount = new_supply_restore_amount


func get_display_name() -> String:
	return GameText.get_text(display_name_key)


func get_description() -> String:
	return GameText.get_text(description_key)
