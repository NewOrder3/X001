extends "res://Tests/TestCase.gd"


func test_online_calculation_clamps_modifiers_and_preserves_fractional_stamina_recovery() -> void:
	var state: SurvivalState = _create_state()
	state.supply = 100.0
	state.durability = 100.0
	state.stamina = 3
	state.stamina_recovery_remainder_seconds = 890.0
	var result: SurvivalCalculationResult = SurvivalCalculator.calculate_online(
		state, _create_config(), 20.0, 9.0, 9.0
	)
	assert_true(is_equal_approx(result.supply, 99.16666666666667))
	assert_eq(result.durability, 99.99166666666666)
	assert_eq(result.stamina, 4)
	assert_eq(result.stamina_recovery_remainder_seconds, 10.0)


func test_depleted_supply_uses_accelerated_recovery_until_safe_line() -> void:
	var state: SurvivalState = _create_state()
	state.supply = 0.0
	state.supply_status = SurvivalState.IndicatorStatus.DEPLETED
	var config: SurvivalConfigDefinition = _create_config()
	var first_result: SurvivalCalculationResult = SurvivalCalculator.calculate_online(state, config, 60.0)
	assert_eq(first_result.supply, 1.5)
	assert_true(first_result.supply_recovery_accelerated)
	assert_eq(first_result.supply_status, SurvivalState.IndicatorStatus.WARNING)

	state.supply = 9.0
	state.supply_recovery_accelerated = true
	var second_result: SurvivalCalculationResult = SurvivalCalculator.calculate_online(state, config, 60.0)
	assert_eq(second_result.supply, 9.5)
	assert_true(second_result.supply_recovery_accelerated)
	var third_result: SurvivalCalculationResult = SurvivalCalculator.calculate_online(state, config, 120.0)
	assert_eq(third_result.supply, 10.0)
	assert_false(third_result.supply_recovery_accelerated)


func test_offline_calculation_keeps_supply_above_minimum_and_respects_stamina_toggle() -> void:
	var state: SurvivalState = _create_state()
	state.supply = 100.0
	state.durability = 44.0
	state.stamina = 3
	var config: SurvivalConfigDefinition = _create_config()
	var result: SurvivalCalculationResult = SurvivalCalculator.calculate_offline(state, config, 8.0 * 3600.0)
	assert_eq(result.supply, 1.0)
	assert_eq(result.durability, 44.0)
	assert_eq(result.stamina, 10)

	config.stamina_offline_recovery = false
	var disabled_result: SurvivalCalculationResult = SurvivalCalculator.calculate_offline(state, config, 3600.0)
	assert_eq(disabled_result.stamina, 3)


func test_large_and_small_online_steps_produce_the_same_result() -> void:
	var config: SurvivalConfigDefinition = _create_config()
	var large_step_state: SurvivalState = _create_state()
	large_step_state.supply = 80.0
	large_step_state.durability = 90.0
	large_step_state.stamina = 2
	var large_step: SurvivalCalculationResult = SurvivalCalculator.calculate_online(
		large_step_state, config, 60.0, 0.2, 0.1
	)

	var small_step_state: SurvivalState = _create_state()
	small_step_state.supply = 80.0
	small_step_state.durability = 90.0
	small_step_state.stamina = 2
	for _step: int in 12:
		var small_step: SurvivalCalculationResult = SurvivalCalculator.calculate_online(
			small_step_state, config, 5.0, 0.2, 0.1
		)
		_apply_result(small_step_state, small_step)

	assert_true(is_equal_approx(large_step.supply, small_step_state.supply))
	assert_true(is_equal_approx(large_step.durability, small_step_state.durability))
	assert_eq(large_step.stamina, small_step_state.stamina)
	assert_true(is_equal_approx(large_step.stamina_recovery_remainder_seconds, small_step_state.stamina_recovery_remainder_seconds))


func test_nonpositive_elapsed_time_returns_state_without_change() -> void:
	var state: SurvivalState = _create_state()
	state.supply = 45.0
	state.durability = 55.0
	state.stamina = 4
	state.supply_status = SurvivalState.IndicatorStatus.WARNING
	var result: SurvivalCalculationResult = SurvivalCalculator.calculate_offline(state, _create_config(), -1.0)
	assert_eq(result.supply, 45.0)
	assert_eq(result.durability, 55.0)
	assert_eq(result.stamina, 4)
	assert_eq(result.supply_status, SurvivalState.IndicatorStatus.WARNING)


func _create_state() -> SurvivalState:
	var state: SurvivalState = SurvivalState.new()
	state.config_id = &"survival_fixture_default"
	return state


func _create_config() -> SurvivalConfigDefinition:
	return SurvivalConfigDefinition.new(
		&"survival_fixture_default", 100.0, 100.0, 1.0, 0.3, 1.0, 0.5, 3.0,
		10.0, 0.5, 2.0, 2.0, 25.0, 30.0, 30.0, 35.0, 5.0, 10, 1, 1, 15, true,
		2, 3, 0.0,
	)


func _apply_result(state: SurvivalState, result: SurvivalCalculationResult) -> void:
	state.supply = result.supply
	state.durability = result.durability
	state.stamina = result.stamina
	state.supply_status = result.supply_status
	state.durability_status = result.durability_status
	state.stamina_status = result.stamina_status
	state.supply_recovery_accelerated = result.supply_recovery_accelerated
	state.stamina_recovery_remainder_seconds = result.stamina_recovery_remainder_seconds
