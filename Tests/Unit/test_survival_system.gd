extends "res://Tests/TestCase.gd"


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
	assert_true(is_equal_approx(state.supply, 99.95833333333333))
	assert_true(is_equal_approx(state.durability, 99.99930555555555))


func test_paused_simulation_does_not_change_survival() -> void:
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(43), session.get_last_error())
	var state: SurvivalState = session.get_survival_state()
	var clock: SimulationClock = session.get_simulation_clock()
	clock.pause()
	assert_eq(session.advance_simulation(10.0), 0)
	assert_eq(state.supply, 100.0)
