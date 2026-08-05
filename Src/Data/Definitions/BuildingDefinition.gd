class_name BuildingDefinition
extends RefCounted

## Immutable static content data shared by every placed building instance.

var id: StringName
var display_name_key: StringName
var description_key: StringName
var footprint: Vector2i
var build_cost: Dictionary[StringName, int]
var capability_tags: Array[StringName]
var recipe_id: StringName
var storage_capacity_bonus: Dictionary[StringName, int]
var durability_recovery_per_minute: float
var durability_recovery_accelerated_multiplier: float


func _init(
	new_id: StringName,
	new_display_name_key: StringName,
	new_description_key: StringName,
	new_footprint: Vector2i,
	new_build_cost: Dictionary[StringName, int] = {},
	new_capability_tags: Array[StringName] = [],
	new_recipe_id: StringName = &"",
	new_storage_capacity_bonus: Dictionary[StringName, int] = {},
	new_durability_recovery_per_minute: float = 0.0,
	new_durability_recovery_accelerated_multiplier: float = 1.0,
) -> void:
	id = new_id
	display_name_key = new_display_name_key
	description_key = new_description_key
	footprint = new_footprint
	build_cost = new_build_cost.duplicate()
	capability_tags = new_capability_tags.duplicate()
	recipe_id = new_recipe_id
	storage_capacity_bonus = new_storage_capacity_bonus.duplicate()
	durability_recovery_per_minute = new_durability_recovery_per_minute
	durability_recovery_accelerated_multiplier = new_durability_recovery_accelerated_multiplier


func get_display_name() -> String:
	return GameText.get_text(display_name_key)


func get_description() -> String:
	return GameText.get_text(description_key)
