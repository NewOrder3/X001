class_name OfflineSettlementReport
extends RefCounted

## Immutable summary of one offline settlement. It is presentation data, not saved state.

var succeeded: bool
var settled: bool
var elapsed_seconds: int
var supply_before: float
var supply_after: float
var durability_before: float
var durability_after: float
var stamina_before: int
var stamina_after: int
var message: String


func _init(
	new_succeeded: bool,
	new_settled: bool,
	new_elapsed_seconds: int,
	new_supply_before: float,
	new_supply_after: float,
	new_durability_before: float,
	new_durability_after: float,
	new_stamina_before: int,
	new_stamina_after: int,
	new_message: String = "",
) -> void:
	succeeded = new_succeeded
	settled = new_settled
	elapsed_seconds = new_elapsed_seconds
	supply_before = new_supply_before
	supply_after = new_supply_after
	durability_before = new_durability_before
	durability_after = new_durability_after
	stamina_before = new_stamina_before
	stamina_after = new_stamina_after
	message = new_message


static func completed(
	elapsed_seconds_value: int,
	supply_before_value: float,
	supply_after_value: float,
	durability_before_value: float,
	durability_after_value: float,
	stamina_before_value: int,
	stamina_after_value: int,
) -> OfflineSettlementReport:
	return OfflineSettlementReport.new(
		true,
		true,
		elapsed_seconds_value,
		supply_before_value,
		supply_after_value,
		durability_before_value,
		durability_after_value,
		stamina_before_value,
		stamina_after_value,
	)


static func skipped(message_text: String = "") -> OfflineSettlementReport:
	return OfflineSettlementReport.new(false, false, 0, 0.0, 0.0, 0.0, 0.0, 0, 0, message_text)


static func no_changes(
	supply_value: float,
	durability_value: float,
	stamina_value: int,
) -> OfflineSettlementReport:
	return OfflineSettlementReport.new(
		true,
		false,
		0,
		supply_value,
		supply_value,
		durability_value,
		durability_value,
		stamina_value,
		stamina_value,
	)


func has_changes() -> bool:
	return settled and (
		not is_equal_approx(supply_before, supply_after)
		or not is_equal_approx(durability_before, durability_after)
		or stamina_before != stamina_after
	)
