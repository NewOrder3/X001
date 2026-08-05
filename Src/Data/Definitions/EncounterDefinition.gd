class_name EncounterDefinition
extends RefCounted

## Immutable outcome content resolved by the deterministic exploration stream.

enum OutcomeType {
	RESOURCE,
	EMPTY,
	STORM,
}

var id: StringName
var display_name_key: StringName
var description_key: StringName
var outcome_type: OutcomeType
var reward_items: Dictionary[StringName, int]
var durability_loss: float


func _init(
	new_id: StringName,
	new_display_name_key: StringName,
	new_description_key: StringName,
	new_outcome_type: OutcomeType,
	new_reward_items: Dictionary[StringName, int] = {},
	new_durability_loss: float = 0.0,
) -> void:
	id = new_id
	display_name_key = new_display_name_key
	description_key = new_description_key
	outcome_type = new_outcome_type
	reward_items = new_reward_items.duplicate()
	durability_loss = new_durability_loss


func get_display_name() -> String:
	return GameText.get_text(display_name_key)


func get_description() -> String:
	return GameText.get_text(description_key)
