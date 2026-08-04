class_name SurvivalCalculationResult
extends RefCounted

## Immutable output of SurvivalCalculator. SurvivalSystem applies this to SurvivalState.

var supply: float
var durability: float
var stamina: int
var supply_status: SurvivalState.IndicatorStatus
var durability_status: SurvivalState.IndicatorStatus
var stamina_status: SurvivalState.IndicatorStatus
var supply_recovery_accelerated: bool
var durability_recovery_accelerated: bool
var stamina_recovery_remainder_seconds: float


func _init(
	new_supply: float,
	new_durability: float,
	new_stamina: int,
	new_supply_status: SurvivalState.IndicatorStatus,
	new_durability_status: SurvivalState.IndicatorStatus,
	new_stamina_status: SurvivalState.IndicatorStatus,
	new_supply_recovery_accelerated: bool,
	new_stamina_recovery_remainder_seconds: float,
	new_durability_recovery_accelerated: bool = false,
) -> void:
	supply = new_supply
	durability = new_durability
	stamina = new_stamina
	supply_status = new_supply_status
	durability_status = new_durability_status
	stamina_status = new_stamina_status
	supply_recovery_accelerated = new_supply_recovery_accelerated
	stamina_recovery_remainder_seconds = new_stamina_recovery_remainder_seconds
	durability_recovery_accelerated = new_durability_recovery_accelerated
