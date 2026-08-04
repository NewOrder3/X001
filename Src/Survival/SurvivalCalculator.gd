class_name SurvivalCalculator
extends RefCounted

## Pure survival rules. It neither reads clocks nor mutates SurvivalState.


static func calculate_online(
	state: SurvivalState,
	config: SurvivalConfigDefinition,
	elapsed_seconds: float,
	supply_modifier_sum: float = 0.0,
	durability_modifier_sum: float = 0.0,
	durability_recovery_per_minute: float = 0.0,
	durability_recovery_accelerated_multiplier: float = 1.0,
) -> SurvivalCalculationResult:
	assert(state != null, "SurvivalCalculator.calculate_online requires a SurvivalState.")
	assert(config != null, "SurvivalCalculator.calculate_online requires a SurvivalConfigDefinition.")
	if state == null or config == null:
		return null
	if elapsed_seconds <= 0.0:
		return _result_from_state(state)

	var clamped_supply_modifier: float = clampf(supply_modifier_sum, 0.0, config.supply_modifier_cap)
	var clamped_durability_modifier: float = clampf(durability_modifier_sum, 0.0, config.durability_modifier_cap)
	var supply_loss: float = config.online_supply_rate_per_minute * (1.0 + clamped_supply_modifier) * elapsed_seconds / 60.0
	var durability_loss: float = config.online_durability_loss_per_hour * (1.0 + clamped_durability_modifier) * elapsed_seconds / 3600.0
	var supply_after_loss: float = maxf(state.supply - supply_loss, 0.0)
	var recovery_accelerated: bool = state.supply_recovery_accelerated or supply_after_loss <= 0.0
	var recovery_multiplier: float = config.passive_recovery_accelerated_multiplier if recovery_accelerated else 1.0
	var supply_recovery: float = config.passive_supply_recovery_per_minute * recovery_multiplier * elapsed_seconds / 60.0
	var final_supply: float = minf(supply_after_loss + supply_recovery, config.max_supply)
	if final_supply >= config.passive_recovery_accelerated_threshold:
		recovery_accelerated = false

	var durability_after_loss: float = maxf(state.durability - durability_loss, 0.0)
	var durability_accelerated: bool = state.durability_recovery_accelerated or durability_after_loss <= 0.0
	var durability_multiplier: float = durability_recovery_accelerated_multiplier if durability_accelerated else 1.0
	var durability_recovery: float = maxf(durability_recovery_per_minute, 0.0) * maxf(durability_multiplier, 1.0) * elapsed_seconds / 60.0
	var final_durability: float = clampf(durability_after_loss + durability_recovery, 0.0, config.max_durability)
	if final_durability > 0.0:
		durability_accelerated = false
	var stamina_data: Dictionary[StringName, Variant] = _recover_stamina(
		state.stamina,
		state.stamina_recovery_remainder_seconds,
		elapsed_seconds,
		config,
	)
	var final_stamina: int = stamina_data[&"stamina"] as int
	var final_remainder: float = stamina_data[&"remainder"] as float
	return SurvivalCalculationResult.new(
		final_supply,
		final_durability,
		final_stamina,
		_get_status(final_supply, config.supply_warning_threshold),
		_get_status(final_durability, config.durability_warning_threshold),
		_get_status(float(final_stamina), float(config.stamina_warning_threshold)),
		recovery_accelerated,
		final_remainder,
		durability_accelerated,
	)


static func calculate_offline(
	state: SurvivalState,
	config: SurvivalConfigDefinition,
	elapsed_seconds: float,
) -> SurvivalCalculationResult:
	assert(state != null, "SurvivalCalculator.calculate_offline requires a SurvivalState.")
	assert(config != null, "SurvivalCalculator.calculate_offline requires a SurvivalConfigDefinition.")
	if state == null or config == null:
		return null
	if elapsed_seconds <= 0.0:
		return _result_from_state(state)

	var supply_loss: float = config.offline_supply_rate_per_minute * elapsed_seconds / 60.0
	var final_supply: float = maxf(config.offline_supply_minimum, state.supply - supply_loss)
	var final_stamina: int = state.stamina
	var final_remainder: float = state.stamina_recovery_remainder_seconds
	if config.stamina_offline_recovery:
		var stamina_data: Dictionary[StringName, Variant] = _recover_stamina(
			state.stamina,
			state.stamina_recovery_remainder_seconds,
			elapsed_seconds,
			config,
		)
		final_stamina = stamina_data[&"stamina"] as int
		final_remainder = stamina_data[&"remainder"] as float

	return SurvivalCalculationResult.new(
		final_supply,
		clampf(state.durability, 0.0, config.max_durability),
		final_stamina,
		_get_status(final_supply, config.supply_warning_threshold),
		_get_status(state.durability, config.durability_warning_threshold),
		_get_status(float(final_stamina), float(config.stamina_warning_threshold)),
		state.supply_recovery_accelerated,
		final_remainder,
	)


static func _recover_stamina(
	current_stamina: int,
	remainder_seconds: float,
	elapsed_seconds: float,
	config: SurvivalConfigDefinition,
) -> Dictionary[StringName, Variant]:
	var clamped_stamina: int = clampi(current_stamina, 0, config.max_stamina)
	if clamped_stamina >= config.max_stamina:
		return {&"stamina": clamped_stamina, &"remainder": 0.0}

	var interval_seconds: float = float(config.stamina_recovery_interval_minutes) * 60.0
	var total_seconds: float = maxf(remainder_seconds, 0.0) + elapsed_seconds
	var recovered_points: int = int(floor(total_seconds / interval_seconds))
	var final_stamina: int = mini(clamped_stamina + recovered_points, config.max_stamina)
	var final_remainder: float = fmod(total_seconds, interval_seconds)
	if final_stamina >= config.max_stamina:
		final_remainder = 0.0
	return {&"stamina": final_stamina, &"remainder": final_remainder}


static func _get_status(value: float, warning_threshold: float) -> SurvivalState.IndicatorStatus:
	if value <= 0.0:
		return SurvivalState.IndicatorStatus.DEPLETED
	if value <= warning_threshold:
		return SurvivalState.IndicatorStatus.WARNING
	return SurvivalState.IndicatorStatus.NORMAL


static func _result_from_state(state: SurvivalState) -> SurvivalCalculationResult:
	return SurvivalCalculationResult.new(
		state.supply,
		state.durability,
		state.stamina,
		state.supply_status,
		state.durability_status,
		state.stamina_status,
		state.supply_recovery_accelerated,
		state.stamina_recovery_remainder_seconds,
		state.durability_recovery_accelerated,
	)
