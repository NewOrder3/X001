class_name SurvivalSystem
extends RefCounted

## Owns survival-state initialization and applies pure calculator results on simulation time.

signal survival_changed(supply: float, durability: float, stamina: int)
signal survival_action_rejected(action_type: StringName, error_code: StringName)
signal action_stamina_consumed(action_type: StringName, stamina_cost: int, remaining_stamina: int)
signal durability_loss_applied(source_id: StringName, durability_loss: float, remaining_durability: float)
signal offline_settlement_completed(report: OfflineSettlementReport)

const ACTION_EXPLORE: StringName = &"action_explore"
const ACTION_BATTLE: StringName = &"action_battle"

const ERROR_INVALID_ACTION: StringName = &"invalid_survival_action"
const ERROR_INVALID_SURVIVAL_STATE: StringName = &"invalid_survival_state"
const ERROR_DURABILITY_DEPLETED: StringName = &"durability_depleted"
const ERROR_INSUFFICIENT_STAMINA: StringName = &"insufficient_stamina"
const ERROR_INVALID_DURABILITY_LOSS: StringName = &"invalid_durability_loss"

var _data_registry: DataRegistry
var _clock: SimulationClock
var _accumulated_seconds: float = 0.0


func _init(data_registry: DataRegistry, clock: SimulationClock) -> void:
	_data_registry = data_registry
	_clock = clock
	if _clock != null:
		_clock.simulation_tick.connect(_on_simulation_tick)


func initialize_new_state(
	state: SurvivalState,
	config_id: StringName,
	current_unix_seconds: int,
) -> bool:
	var config: SurvivalConfigDefinition = _get_config(config_id)
	if state == null or config == null:
		return false

	state.config_id = config.id
	state.supply = config.max_supply
	state.durability = config.max_durability
	state.stamina = config.max_stamina
	state.supply_status = SurvivalState.IndicatorStatus.NORMAL
	state.durability_status = SurvivalState.IndicatorStatus.NORMAL
	state.stamina_status = SurvivalState.IndicatorStatus.NORMAL
	state.supply_recovery_accelerated = false
	state.durability_recovery_accelerated = false
	state.stamina_recovery_remainder_seconds = 0.0
	state.last_online_unix_seconds = maxi(current_unix_seconds, 0)
	state.last_offline_settlement_unix_seconds = 0
	state.offline_settlement_pending = false
	_accumulated_seconds = 0.0
	return true


func activate_loaded_state(state: SurvivalState, current_unix_seconds: int) -> OfflineSettlementReport:
	if state == null:
		return OfflineSettlementReport.skipped(GameText.get_text(&"message.survival.state_unavailable"))
	if state.config_id == &"":
		if not initialize_new_state(state, &"survival_default", current_unix_seconds):
			return OfflineSettlementReport.skipped(GameText.get_text(&"message.survival.state_unavailable"))
		return OfflineSettlementReport.no_changes(state.supply, state.durability, state.stamina)
	if _get_config(state.config_id) == null:
		return OfflineSettlementReport.skipped(GameText.get_text(&"message.survival.state_unavailable"))
	_accumulated_seconds = 0.0
	return settle_offline(state, current_unix_seconds)


func settle_offline(state: SurvivalState, current_unix_seconds: int) -> OfflineSettlementReport:
	var config: SurvivalConfigDefinition = get_config(state)
	if state == null or config == null:
		return OfflineSettlementReport.skipped(GameText.get_text(&"message.survival.state_unavailable"))

	var normalized_now: int = maxi(current_unix_seconds, 0)
	var settlement_time: int = maxi(normalized_now, state.last_online_unix_seconds)
	if not state.offline_settlement_pending:
		state.last_online_unix_seconds = settlement_time
		return OfflineSettlementReport.no_changes(state.supply, state.durability, state.stamina)

	var elapsed_seconds: int = settlement_time - state.last_online_unix_seconds
	var supply_before: float = state.supply
	var durability_before: float = state.durability
	var stamina_before: int = state.stamina
	var result: SurvivalCalculationResult = SurvivalCalculator.calculate_offline(
		state,
		config,
		float(elapsed_seconds),
	)
	_apply_result(state, result)
	state.last_online_unix_seconds = settlement_time
	state.last_offline_settlement_unix_seconds = settlement_time
	state.offline_settlement_pending = false
	var report: OfflineSettlementReport = OfflineSettlementReport.completed(
		elapsed_seconds,
		supply_before,
		state.supply,
		durability_before,
		state.durability,
		stamina_before,
		state.stamina,
	)
	if report.has_changes():
		survival_changed.emit(state.supply, state.durability, state.stamina)
	offline_settlement_completed.emit(report)
	return report


func get_config(state: SurvivalState) -> SurvivalConfigDefinition:
	if state == null:
		return null
	return _get_config(state.config_id)


func restore_supply(state: SurvivalState, amount: float) -> bool:
	var config: SurvivalConfigDefinition = get_config(state)
	if state == null or config == null or amount <= 0.0 or state.supply >= config.max_supply:
		return false
	state.supply = minf(config.max_supply, state.supply + amount)
	if state.supply <= 0.0:
		state.supply_status = SurvivalState.IndicatorStatus.DEPLETED
	elif state.supply <= config.supply_warning_threshold:
		state.supply_status = SurvivalState.IndicatorStatus.WARNING
	else:
		state.supply_status = SurvivalState.IndicatorStatus.NORMAL
	if state.supply >= config.passive_recovery_accelerated_threshold:
		state.supply_recovery_accelerated = false
	survival_changed.emit(state.supply, state.durability, state.stamina)
	return true


func can_perform_action(state: SurvivalState, action_type: StringName) -> SurvivalActionResult:
	var config: SurvivalConfigDefinition = get_config(state)
	if state == null or config == null:
		return SurvivalActionResult.failure(
			action_type,
			ERROR_INVALID_SURVIVAL_STATE,
			GameText.get_text(&"message.survival.state_unavailable"),
		)

	var stamina_cost: int = _get_action_stamina_cost(config, action_type)
	if stamina_cost <= 0:
		return SurvivalActionResult.failure(
			action_type,
			ERROR_INVALID_ACTION,
			GameText.get_text(&"message.survival.action_unavailable"),
		)
	# Depleted supplies lower manual-operation efficiency but do not block actions.
	if action_type == ACTION_BATTLE and state.durability <= 0.0:
		return SurvivalActionResult.failure(
			action_type,
			ERROR_DURABILITY_DEPLETED,
			GameText.get_text(&"message.survival.repair_before_battle"),
		)
	if state.stamina < stamina_cost:
		return SurvivalActionResult.failure(
			action_type,
			ERROR_INSUFFICIENT_STAMINA,
			GameText.get_text(&"message.survival.insufficient_stamina"),
		)
	return SurvivalActionResult.success(action_type, stamina_cost)


func consume_action_stamina(state: SurvivalState, action_type: StringName) -> SurvivalActionResult:
	var result: SurvivalActionResult = can_perform_action(state, action_type)
	if not result.succeeded:
		survival_action_rejected.emit(action_type, result.error_code)
		return result

	var config: SurvivalConfigDefinition = get_config(state)
	state.stamina -= result.stamina_cost
	state.stamina_status = _get_status(float(state.stamina), float(config.stamina_warning_threshold))
	survival_changed.emit(state.supply, state.durability, state.stamina)
	action_stamina_consumed.emit(action_type, result.stamina_cost, state.stamina)
	return result


func apply_durability_loss(
	state: SurvivalState,
	source_id: StringName,
	amount: float,
) -> SurvivalActionResult:
	var config: SurvivalConfigDefinition = get_config(state)
	if state == null or config == null:
		return SurvivalActionResult.failure(
			source_id,
			ERROR_INVALID_SURVIVAL_STATE,
			GameText.get_text(&"message.survival.state_unavailable"),
		)
	if source_id == &"" or amount <= 0.0:
		return SurvivalActionResult.failure(
			source_id,
			ERROR_INVALID_DURABILITY_LOSS,
			GameText.get_text(&"message.survival.invalid_durability_loss"),
		)

	var durability_loss: float = minf(state.durability, amount)
	state.durability = maxf(state.durability - amount, 0.0)
	state.durability_status = _get_status(state.durability, config.durability_warning_threshold)
	if state.durability <= 0.0:
		state.durability_recovery_accelerated = true
	survival_changed.emit(state.supply, state.durability, state.stamina)
	durability_loss_applied.emit(source_id, durability_loss, state.durability)
	return SurvivalActionResult.success(source_id, 0, durability_loss)


func _on_simulation_tick(delta_seconds: float) -> void:
	_accumulated_seconds += delta_seconds


func advance(
	state: SurvivalState,
	durability_recovery_per_minute: float = 0.0,
	durability_recovery_accelerated_multiplier: float = 1.0,
) -> int:
	var config: SurvivalConfigDefinition = get_config(state)
	if state == null or config == null:
		return 0

	var settled_interval_count: int = 0
	while _accumulated_seconds >= config.simulation_interval_seconds:
		_accumulated_seconds -= config.simulation_interval_seconds
		var result: SurvivalCalculationResult = SurvivalCalculator.calculate_online(
			state,
			config,
			config.simulation_interval_seconds,
			0.0,
			0.0,
			durability_recovery_per_minute,
			durability_recovery_accelerated_multiplier,
		)
		_apply_result(state, result)
		settled_interval_count += 1
	if settled_interval_count > 0:
		survival_changed.emit(state.supply, state.durability, state.stamina)
	return settled_interval_count


func _get_config(config_id: StringName) -> SurvivalConfigDefinition:
	if _data_registry == null or config_id == &"" or not _data_registry.has_survival_config(config_id):
		return null
	return _data_registry.get_survival_config(config_id)


func _get_action_stamina_cost(config: SurvivalConfigDefinition, action_type: StringName) -> int:
	if action_type == ACTION_EXPLORE:
		return config.explore_stamina_cost
	if action_type == ACTION_BATTLE:
		return config.battle_stamina_cost
	return 0


func _get_status(value: float, warning_threshold: float) -> SurvivalState.IndicatorStatus:
	if value <= 0.0:
		return SurvivalState.IndicatorStatus.DEPLETED
	if value <= warning_threshold:
		return SurvivalState.IndicatorStatus.WARNING
	return SurvivalState.IndicatorStatus.NORMAL


func _apply_result(state: SurvivalState, result: SurvivalCalculationResult) -> void:
	state.supply = result.supply
	state.durability = result.durability
	state.stamina = result.stamina
	state.supply_status = result.supply_status
	state.durability_status = result.durability_status
	state.stamina_status = result.stamina_status
	state.supply_recovery_accelerated = result.supply_recovery_accelerated
	state.durability_recovery_accelerated = result.durability_recovery_accelerated
	state.stamina_recovery_remainder_seconds = result.stamina_recovery_remainder_seconds
