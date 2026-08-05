class_name ExplorationResult
extends RefCounted

## Read-only voyage result consumed by map UI after ExplorationSystem commits state.

var succeeded: bool
var error_code: StringName
var message: String
var origin_region_id: StringName
var target_region_id: StringName
var encounter_id: StringName
var reward_items: Dictionary[StringName, int]
var durability_loss: float
var stamina_cost: int


func _init(
	new_succeeded: bool,
	new_error_code: StringName,
	new_message: String,
	new_origin_region_id: StringName = &"",
	new_target_region_id: StringName = &"",
	new_encounter_id: StringName = &"",
	new_reward_items: Dictionary[StringName, int] = {},
	new_durability_loss: float = 0.0,
	new_stamina_cost: int = 0,
) -> void:
	succeeded = new_succeeded
	error_code = new_error_code
	message = new_message
	origin_region_id = new_origin_region_id
	target_region_id = new_target_region_id
	encounter_id = new_encounter_id
	reward_items = new_reward_items.duplicate()
	durability_loss = new_durability_loss
	stamina_cost = new_stamina_cost


static func failure(error: StringName, message_text: String) -> ExplorationResult:
	return ExplorationResult.new(false, error, message_text)
