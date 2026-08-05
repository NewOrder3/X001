class_name SurvivalActionResult
extends RefCounted

## Explicit outcome returned by SurvivalSystem action and durability interfaces.

var succeeded: bool
var action_type: StringName
var error_code: StringName
var message: String
var stamina_cost: int
var durability_loss: float


func _init(
	new_succeeded: bool,
	new_action_type: StringName,
	new_error_code: StringName,
	new_message: String,
	new_stamina_cost: int = 0,
	new_durability_loss: float = 0.0,
) -> void:
	succeeded = new_succeeded
	action_type = new_action_type
	error_code = new_error_code
	message = new_message
	stamina_cost = new_stamina_cost
	durability_loss = new_durability_loss


static func success(
	action_type_value: StringName,
	stamina_cost_value: int = 0,
	durability_loss_value: float = 0.0,
	message_text: String = "",
) -> SurvivalActionResult:
	return SurvivalActionResult.new(
		true,
		action_type_value,
		&"",
		message_text,
		stamina_cost_value,
		durability_loss_value,
	)


static func failure(
	action_type_value: StringName,
	error: StringName,
	message_text: String,
) -> SurvivalActionResult:
	return SurvivalActionResult.new(false, action_type_value, error, message_text)
