class_name ItemDefinition
extends RefCounted

## Immutable static content data shared by every item instance/reference.

var id: StringName
var display_name: String
var description: String
var base_capacity: int
var supply_restore_amount: float


func _init(
	new_id: StringName,
	new_display_name: String,
	new_description: String,
	new_base_capacity: int = 99,
	new_supply_restore_amount: float = 0.0,
) -> void:
	id = new_id
	display_name = new_display_name
	description = new_description
	base_capacity = new_base_capacity
	supply_restore_amount = new_supply_restore_amount
