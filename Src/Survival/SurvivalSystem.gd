class_name SurvivalSystem
extends RefCounted

## Owns survival-state initialization and applies pure calculator results on simulation time.

signal survival_changed(supply: float, durability: float, stamina: int)

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
	state.stamina_recovery_remainder_seconds = 0.0
	state.last_online_unix_seconds = maxi(current_unix_seconds, 0)
	state.last_offline_settlement_unix_seconds = 0
	state.offline_settlement_pending = false
	_accumulated_seconds = 0.0
	return true


func activate_loaded_state(state: SurvivalState, current_unix_seconds: int) -> bool:
	if state == null:
		return false
	if state.config_id == &"":
		return initialize_new_state(state, &"survival_default", current_unix_seconds)
	if _get_config(state.config_id) == null:
		return false
	state.last_online_unix_seconds = maxi(current_unix_seconds, 0)
	_accumulated_seconds = 0.0
	return true


func get_config(state: SurvivalState) -> SurvivalConfigDefinition:
	if state == null:
		return null
	return _get_config(state.config_id)


func _on_simulation_tick(delta_seconds: float) -> void:
	_accumulated_seconds += delta_seconds


func advance(state: SurvivalState) -> int:
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


func _apply_result(state: SurvivalState, result: SurvivalCalculationResult) -> void:
	state.supply = result.supply
	state.durability = result.durability
	state.stamina = result.stamina
	state.supply_status = result.supply_status
	state.durability_status = result.durability_status
	state.stamina_status = result.stamina_status
	state.supply_recovery_accelerated = result.supply_recovery_accelerated
	state.stamina_recovery_remainder_seconds = result.stamina_recovery_remainder_seconds
