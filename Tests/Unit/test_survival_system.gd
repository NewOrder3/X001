extends "res://Tests/TestCase.gd"

var _last_rejected_action: StringName = &""
var _last_rejection_code: StringName = &""
var _rejection_count: int = 0


func test_new_game_initializes_survival_from_definition_and_settles_every_five_seconds() -> void:
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(42), session.get_last_error())
	var state: SurvivalState = session.get_survival_state()
	assert_not_null(state)
	assert_eq(state.config_id, &"survival_default")
	assert_eq(state.supply, 100.0)
	assert_eq(state.durability, 100.0)
	assert_eq(state.stamina, 10)

	for _step: int in 24:
		session.advance_simulation(0.2)
	assert_eq(state.supply, 100.0)
	session.advance_simulation(0.2)
	assert_true(is_equal_approx(state.supply, 99.91666666666667))
	assert_true(is_equal_approx(state.durability, 99.99930555555555))


func test_paused_simulation_does_not_change_survival() -> void:
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(43), session.get_last_error())
	var state: SurvivalState = session.get_survival_state()
	var clock: SimulationClock = session.get_simulation_clock()
	clock.pause()
	assert_eq(session.advance_simulation(10.0), 0)
	assert_eq(state.supply, 100.0)


func test_depleted_supply_does_not_block_exploration_action() -> void:
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(44), session.get_last_error())
	var state: SurvivalState = session.get_survival_state()
	state.supply = 0.0

	var check_result: SurvivalActionResult = session.can_perform_survival_action(SurvivalSystem.ACTION_EXPLORE)
	var consume_result: SurvivalActionResult = session.consume_survival_action_stamina(SurvivalSystem.ACTION_EXPLORE)

	assert_true(check_result.succeeded, check_result.message)
	assert_true(consume_result.succeeded, consume_result.message)
	assert_eq(state.stamina, 9)
	assert_eq(state.supply, 0.0)


func test_depleted_durability_allows_exploration_and_rejects_battle() -> void:
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(45), session.get_last_error())
	var state: SurvivalState = session.get_survival_state()
	state.durability = 0.0

	var explore_result: SurvivalActionResult = session.can_perform_survival_action(SurvivalSystem.ACTION_EXPLORE)
	var battle_result: SurvivalActionResult = session.can_perform_survival_action(SurvivalSystem.ACTION_BATTLE)

	assert_true(explore_result.succeeded, explore_result.message)
	assert_false(battle_result.succeeded)
	assert_eq(battle_result.error_code, SurvivalSystem.ERROR_DURABILITY_DEPLETED)
	assert_eq(state.stamina, 10)


func test_insufficient_stamina_rejects_without_mutation_and_emits_feedback() -> void:
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(46), session.get_last_error())
	var state: SurvivalState = session.get_survival_state()
	state.stamina = 0
	_reset_rejection_feedback()
	session.get_survival_system().survival_action_rejected.connect(_on_survival_action_rejected)

	var result: SurvivalActionResult = session.consume_survival_action_stamina(SurvivalSystem.ACTION_EXPLORE)

	assert_false(result.succeeded)
	assert_eq(result.error_code, SurvivalSystem.ERROR_INSUFFICIENT_STAMINA)
	assert_eq(state.stamina, 0)
	assert_eq(_rejection_count, 1)
	assert_eq(_last_rejected_action, SurvivalSystem.ACTION_EXPLORE)
	assert_eq(_last_rejection_code, SurvivalSystem.ERROR_INSUFFICIENT_STAMINA)


func test_exact_stamina_cost_is_consumed_once() -> void:
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(47), session.get_last_error())
	var state: SurvivalState = session.get_survival_state()
	state.stamina = 1

	var first_result: SurvivalActionResult = session.consume_survival_action_stamina(SurvivalSystem.ACTION_BATTLE)
	var second_result: SurvivalActionResult = session.consume_survival_action_stamina(SurvivalSystem.ACTION_BATTLE)

	assert_true(first_result.succeeded, first_result.message)
	assert_eq(first_result.stamina_cost, 1)
	assert_eq(state.stamina, 0)
	assert_false(second_result.succeeded)
	assert_eq(second_result.error_code, SurvivalSystem.ERROR_INSUFFICIENT_STAMINA)
	assert_eq(state.stamina, 0)


func test_durability_loss_clamps_at_zero_and_updates_status() -> void:
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(48), session.get_last_error())
	var state: SurvivalState = session.get_survival_state()
	state.durability = 2.5

	var result: SurvivalActionResult = session.apply_survival_durability_loss(&"event_storm", 10.0)

	assert_true(result.succeeded, result.message)
	assert_eq(result.durability_loss, 2.5)
	assert_eq(state.durability, 0.0)
	assert_eq(state.durability_status, SurvivalState.IndicatorStatus.DEPLETED)
	assert_true(state.durability_recovery_accelerated)


func test_zero_hour_offline_settlement_marks_pending_state_as_settled() -> void:
	var state: GameState = _create_pending_offline_state(100, 50.0, 25.0, 3)
	var session: GameSession = GameSession.new()

	assert_true(session.load_state_at(state, 100), session.get_last_error())
	var report: OfflineSettlementReport = session.get_last_offline_settlement_report()

	assert_not_null(report)
	assert_true(report.succeeded)
	assert_true(report.settled)
	assert_eq(report.elapsed_seconds, 0)
	assert_eq(state.survival_state.supply, 50.0)
	assert_eq(state.survival_state.stamina, 3)
	assert_false(state.survival_state.offline_settlement_pending)
	assert_eq(state.survival_state.last_offline_settlement_unix_seconds, 100)


func test_one_hour_offline_settlement_consumes_supply_and_recovers_stamina() -> void:
	var state: GameState = _create_pending_offline_state(0, 100.0, 25.0, 3)
	var session: GameSession = GameSession.new()

	assert_true(session.load_state_at(state, 3600), session.get_last_error())
	var report: OfflineSettlementReport = session.get_last_offline_settlement_report()

	assert_eq(report.elapsed_seconds, 3600)
	assert_eq(state.survival_state.supply, 82.0)
	assert_eq(state.survival_state.durability, 25.0)
	assert_eq(state.survival_state.stamina, 9)
	assert_eq(report.supply_before, 100.0)
	assert_eq(report.supply_after, 82.0)
	assert_eq(report.stamina_before, 3)
	assert_eq(report.stamina_after, 9)


func test_four_and_eight_hour_offline_settlements_respect_configured_minimum() -> void:
	var four_hour_state: GameState = _create_pending_offline_state(0, 100.0, 25.0, 0)
	var four_hour_session: GameSession = GameSession.new()
	assert_true(four_hour_session.load_state_at(four_hour_state, 4 * 3600), four_hour_session.get_last_error())
	assert_eq(four_hour_state.survival_state.supply, 28.0)
	assert_eq(four_hour_state.survival_state.stamina, 10)

	var eight_hour_state: GameState = _create_pending_offline_state(0, 100.0, 25.0, 0)
	var eight_hour_session: GameSession = GameSession.new()
	assert_true(eight_hour_session.load_state_at(eight_hour_state, 8 * 3600), eight_hour_session.get_last_error())
	assert_eq(eight_hour_state.survival_state.supply, 1.0)
	assert_eq(eight_hour_state.survival_state.durability, 25.0)
	assert_eq(eight_hour_state.survival_state.stamina, 10)


func test_long_offline_clock_reversal_and_repeat_settlement_are_idempotent() -> void:
	var long_offline_state: GameState = _create_pending_offline_state(0, 100.0, 25.0, 0)
	var long_offline_session: GameSession = GameSession.new()
	assert_true(long_offline_session.load_state_at(long_offline_state, 30 * 24 * 3600), long_offline_session.get_last_error())
	assert_eq(long_offline_state.survival_state.supply, 1.0)
	assert_eq(long_offline_state.survival_state.durability, 25.0)
	assert_eq(long_offline_state.survival_state.stamina, 10)

	var reversed_clock_state: GameState = _create_pending_offline_state(1000, 50.0, 25.0, 3)
	var reversed_clock_session: GameSession = GameSession.new()
	assert_true(reversed_clock_session.load_state_at(reversed_clock_state, 900), reversed_clock_session.get_last_error())
	assert_eq(reversed_clock_session.get_last_offline_settlement_report().elapsed_seconds, 0)
	assert_eq(reversed_clock_state.survival_state.supply, 50.0)
	assert_eq(reversed_clock_state.survival_state.last_online_unix_seconds, 1000)

	var repeat_state: GameState = _create_pending_offline_state(0, 100.0, 25.0, 3)
	var repeat_session: GameSession = GameSession.new()
	assert_true(repeat_session.load_state_at(repeat_state, 3600), repeat_session.get_last_error())
	assert_eq(repeat_state.survival_state.supply, 82.0)
	assert_true(repeat_session.load_state_at(repeat_state, 7200), repeat_session.get_last_error())
	assert_false(repeat_session.get_last_offline_settlement_report().settled)
	assert_eq(repeat_state.survival_state.supply, 82.0)
	assert_eq(repeat_state.survival_state.last_offline_settlement_unix_seconds, 3600)


func _reset_rejection_feedback() -> void:
	_last_rejected_action = &""
	_last_rejection_code = &""
	_rejection_count = 0


func _on_survival_action_rejected(action_type: StringName, error_code: StringName) -> void:
	_last_rejected_action = action_type
	_last_rejection_code = error_code
	_rejection_count += 1


func _create_pending_offline_state(
	last_online_unix_seconds: int,
	supply: float,
	durability: float,
	stamina: int,
) -> GameState:
	var state: GameState = GameState.new(49)
	state.survival_state.config_id = &"survival_default"
	state.survival_state.supply = supply
	state.survival_state.durability = durability
	state.survival_state.stamina = stamina
	state.survival_state.last_online_unix_seconds = last_online_unix_seconds
	state.survival_state.offline_settlement_pending = true
	return state
