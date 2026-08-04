class_name SurvivalState
extends RefCounted

## Serializable runtime data for the survival rules. SurvivalSystem owns gameplay mutation.

enum IndicatorStatus {
	NORMAL,
	WARNING,
	DEPLETED,
}

var config_id: StringName = &""
var supply: float = 0.0
var durability: float = 0.0
var stamina: int = 0
var supply_status: IndicatorStatus = IndicatorStatus.NORMAL
var durability_status: IndicatorStatus = IndicatorStatus.NORMAL
var stamina_status: IndicatorStatus = IndicatorStatus.NORMAL
var supply_recovery_accelerated: bool = false
var stamina_recovery_remainder_seconds: float = 0.0
var last_online_unix_seconds: int = 0
var last_offline_settlement_unix_seconds: int = 0
var offline_settlement_pending: bool = false


func to_save_data() -> Dictionary:
	return {
		"config_id": String(config_id),
		"supply": supply,
		"durability": durability,
		"stamina": stamina,
		"supply_status": int(supply_status),
		"durability_status": int(durability_status),
		"stamina_status": int(stamina_status),
		"supply_recovery_accelerated": supply_recovery_accelerated,
		"stamina_recovery_remainder_seconds": stamina_recovery_remainder_seconds,
		"last_online_unix_seconds": last_online_unix_seconds,
		"last_offline_settlement_unix_seconds": last_offline_settlement_unix_seconds,
		"offline_settlement_pending": offline_settlement_pending,
	}


func load_from_save_data(data: Dictionary) -> bool:
	var raw_config_id: Variant = data.get("config_id")
	var raw_supply: Variant = data.get("supply")
	var raw_durability: Variant = data.get("durability")
	var raw_stamina: Variant = data.get("stamina")
	var raw_supply_status: Variant = data.get("supply_status")
	var raw_durability_status: Variant = data.get("durability_status")
	var raw_stamina_status: Variant = data.get("stamina_status")
	var raw_supply_recovery_accelerated: Variant = data.get("supply_recovery_accelerated")
	var raw_remainder: Variant = data.get("stamina_recovery_remainder_seconds")
	var raw_last_online: Variant = data.get("last_online_unix_seconds")
	var raw_last_settlement: Variant = data.get("last_offline_settlement_unix_seconds")
	var raw_pending: Variant = data.get("offline_settlement_pending")

	if typeof(raw_config_id) != TYPE_STRING or String(raw_config_id).is_empty():
		return false
	if not _is_nonnegative_number(raw_supply) or not _is_nonnegative_number(raw_durability):
		return false
	if not _is_nonnegative_integer(raw_stamina) or not _is_valid_status(raw_supply_status):
		return false
	if not _is_valid_status(raw_durability_status) or not _is_valid_status(raw_stamina_status):
		return false
	if typeof(raw_supply_recovery_accelerated) != TYPE_BOOL:
		return false
	if not _is_nonnegative_number(raw_remainder):
		return false
	if not _is_nonnegative_integer(raw_last_online) or not _is_nonnegative_integer(raw_last_settlement):
		return false
	if typeof(raw_pending) != TYPE_BOOL:
		return false

	config_id = StringName(raw_config_id)
	supply = float(raw_supply)
	durability = float(raw_durability)
	stamina = int(raw_stamina)
	supply_status = int(raw_supply_status) as IndicatorStatus
	durability_status = int(raw_durability_status) as IndicatorStatus
	stamina_status = int(raw_stamina_status) as IndicatorStatus
	supply_recovery_accelerated = bool(raw_supply_recovery_accelerated)
	stamina_recovery_remainder_seconds = float(raw_remainder)
	last_online_unix_seconds = int(raw_last_online)
	last_offline_settlement_unix_seconds = int(raw_last_settlement)
	offline_settlement_pending = bool(raw_pending)
	return true


func _is_nonnegative_number(value: Variant) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and float(value) >= 0.0


func _is_nonnegative_integer(value: Variant) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and float(value) >= 0.0 and float(value) == floor(float(value))


func _is_valid_status(value: Variant) -> bool:
	return _is_nonnegative_integer(value) and int(value) <= IndicatorStatus.DEPLETED
