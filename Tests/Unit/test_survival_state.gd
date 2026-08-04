extends "res://Tests/TestCase.gd"


func test_save_data_round_trip_preserves_survival_runtime_fields() -> void:
	var source: SurvivalState = SurvivalState.new()
	source.config_id = &"survival_fixture_default"
	source.supply = 56.25
	source.durability = 42.5
	source.stamina = 4
	source.supply_status = SurvivalState.IndicatorStatus.WARNING
	source.durability_status = SurvivalState.IndicatorStatus.WARNING
	source.stamina_status = SurvivalState.IndicatorStatus.NORMAL
	source.supply_recovery_accelerated = true
	source.stamina_recovery_remainder_seconds = 123.5
	source.last_online_unix_seconds = 1_710_000_000
	source.last_offline_settlement_unix_seconds = 1_709_999_000
	source.offline_settlement_pending = true

	var loaded: SurvivalState = SurvivalState.new()
	assert_true(loaded.load_from_save_data(source.to_save_data()))
	assert_eq(loaded.config_id, &"survival_fixture_default")
	assert_eq(loaded.supply, 56.25)
	assert_eq(loaded.durability, 42.5)
	assert_eq(loaded.stamina, 4)
	assert_eq(loaded.supply_status, SurvivalState.IndicatorStatus.WARNING)
	assert_true(loaded.supply_recovery_accelerated)
	assert_eq(loaded.stamina_recovery_remainder_seconds, 123.5)
	assert_eq(loaded.last_online_unix_seconds, 1_710_000_000)
	assert_true(loaded.offline_settlement_pending)


func test_invalid_load_does_not_partially_modify_existing_state() -> void:
	var state: SurvivalState = SurvivalState.new()
	state.config_id = &"survival_fixture_default"
	state.supply = 80.0
	state.stamina = 5

	var invalid_data: Dictionary = state.to_save_data()
	invalid_data["stamina"] = -1
	assert_false(state.load_from_save_data(invalid_data))
	assert_eq(state.config_id, &"survival_fixture_default")
	assert_eq(state.supply, 80.0)
	assert_eq(state.stamina, 5)
