class_name SurvivalConfigDefinition
extends RefCounted

## Immutable survival-rule configuration shared by a game session.

var id: StringName
var max_supply: float
var max_durability: float
var online_supply_rate_per_minute: float
var offline_supply_rate_per_minute: float
var offline_supply_minimum: float
var passive_supply_recovery_per_minute: float
var passive_recovery_accelerated_multiplier: float
var passive_recovery_accelerated_threshold: float
var online_durability_loss_per_hour: float
var supply_modifier_cap: float
var durability_modifier_cap: float
var supply_warning_threshold: float
var supply_safe_line: float
var durability_warning_threshold: float
var durability_safe_line: float
var simulation_interval_seconds: float
var max_stamina: int
var explore_stamina_cost: int
var battle_stamina_cost: int
var stamina_recovery_interval_minutes: int
var stamina_offline_recovery: bool
var stamina_warning_threshold: int
var stamina_safe_line: int
var action_supply_cost: float


func _init(
	new_id: StringName,
	new_max_supply: float,
	new_max_durability: float,
	new_online_supply_rate_per_minute: float,
	new_offline_supply_rate_per_minute: float,
	new_offline_supply_minimum: float,
	new_passive_supply_recovery_per_minute: float,
	new_passive_recovery_accelerated_multiplier: float,
	new_passive_recovery_accelerated_threshold: float,
	new_online_durability_loss_per_hour: float,
	new_supply_modifier_cap: float,
	new_durability_modifier_cap: float,
	new_supply_warning_threshold: float,
	new_supply_safe_line: float,
	new_durability_warning_threshold: float,
	new_durability_safe_line: float,
	new_simulation_interval_seconds: float,
	new_max_stamina: int,
	new_explore_stamina_cost: int,
	new_battle_stamina_cost: int,
	new_stamina_recovery_interval_minutes: int,
	new_stamina_offline_recovery: bool,
	new_stamina_warning_threshold: int,
	new_stamina_safe_line: int,
	new_action_supply_cost: float,
) -> void:
	id = new_id
	max_supply = new_max_supply
	max_durability = new_max_durability
	online_supply_rate_per_minute = new_online_supply_rate_per_minute
	offline_supply_rate_per_minute = new_offline_supply_rate_per_minute
	offline_supply_minimum = new_offline_supply_minimum
	passive_supply_recovery_per_minute = new_passive_supply_recovery_per_minute
	passive_recovery_accelerated_multiplier = new_passive_recovery_accelerated_multiplier
	passive_recovery_accelerated_threshold = new_passive_recovery_accelerated_threshold
	online_durability_loss_per_hour = new_online_durability_loss_per_hour
	supply_modifier_cap = new_supply_modifier_cap
	durability_modifier_cap = new_durability_modifier_cap
	supply_warning_threshold = new_supply_warning_threshold
	supply_safe_line = new_supply_safe_line
	durability_warning_threshold = new_durability_warning_threshold
	durability_safe_line = new_durability_safe_line
	simulation_interval_seconds = new_simulation_interval_seconds
	max_stamina = new_max_stamina
	explore_stamina_cost = new_explore_stamina_cost
	battle_stamina_cost = new_battle_stamina_cost
	stamina_recovery_interval_minutes = new_stamina_recovery_interval_minutes
	stamina_offline_recovery = new_stamina_offline_recovery
	stamina_warning_threshold = new_stamina_warning_threshold
	stamina_safe_line = new_stamina_safe_line
	action_supply_cost = new_action_supply_cost
