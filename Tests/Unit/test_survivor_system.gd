extends "res://Tests/TestCase.gd"


func test_recruitment_rejects_duplicate_unique_survivor() -> void:
	var session: GameSession = _create_session()
	var survivor_system: SurvivorSystem = session.get_survivor_system()
	var state: SurvivorState = session.get_survivor_state()
	assert_true(survivor_system.offer_recruitment(state, &"survivor_marin"))

	var first_result: CommandResult = session.execute_command(RecruitSurvivorCommand.new(&"survivor_marin"))
	var second_result: CommandResult = session.execute_command(RecruitSurvivorCommand.new(&"survivor_marin"))

	assert_true(first_result.succeeded, first_result.message)
	assert_false(second_result.succeeded)
	assert_eq(second_result.error_code, SurvivorSystem.ERROR_ALREADY_RECRUITED)
	assert_eq(state.survivors.size(), 1)
	assert_eq(state.survivors[&"survivor_marin"].level, 1)


func test_upgrade_spends_cost_atomically_and_stops_at_level_ten() -> void:
	var session: GameSession = _create_session()
	var state: GameState = session.get_state()
	var survivor_system: SurvivorSystem = session.get_survivor_system()
	assert_true(survivor_system.offer_recruitment(state.survivor_state, &"survivor_marin"))
	assert_true(session.execute_command(RecruitSurvivorCommand.new(&"survivor_marin")).succeeded)
	var wood_before: int = session.get_item_amount(&"item_wood")

	var upgrade_result: CommandResult = session.execute_command(UpgradeSurvivorCommand.new(&"survivor_marin"))

	assert_true(upgrade_result.succeeded, upgrade_result.message)
	assert_eq(state.survivor_state.survivors[&"survivor_marin"].level, 2)
	assert_eq(session.get_item_amount(&"item_wood"), wood_before - 2)
	state.survivor_state.survivors[&"survivor_marin"].level = SurvivorSystem.MAX_LEVEL
	var wood_at_max: int = session.get_item_amount(&"item_wood")
	var max_result: CommandResult = session.execute_command(UpgradeSurvivorCommand.new(&"survivor_marin"))
	assert_false(max_result.succeeded)
	assert_eq(max_result.error_code, SurvivorSystem.ERROR_MAX_LEVEL)
	assert_eq(session.get_item_amount(&"item_wood"), wood_at_max)


func test_lineup_accepts_only_owned_unique_survivors_and_exposes_passive() -> void:
	var session: GameSession = _create_session()
	var survivor_system: SurvivorSystem = session.get_survivor_system()
	var state: SurvivorState = session.get_survivor_state()
	for survivor_id: StringName in [&"survivor_marin", &"survivor_yue", &"survivor_bo", &"survivor_su"]:
		assert_true(survivor_system.offer_recruitment(state, survivor_id))
		assert_true(session.execute_command(RecruitSurvivorCommand.new(survivor_id)).succeeded)

	var valid_result: CommandResult = session.execute_command(SetLineupCommand.new([
		&"survivor_marin", &"survivor_yue", &"survivor_bo",
	]))
	var full_result: CommandResult = session.execute_command(SetLineupCommand.new([
		&"survivor_marin", &"survivor_yue", &"survivor_bo", &"survivor_su",
	]))
	var duplicate_result: CommandResult = session.execute_command(SetLineupCommand.new([
		&"survivor_marin", &"survivor_marin",
	]))

	assert_true(valid_result.succeeded, valid_result.message)
	assert_eq(state.lineup_ids.size(), SurvivorState.MAX_LINEUP_SIZE)
	assert_eq(survivor_system.get_lineup_passive_value(state, &"passive_attack"), 2.0)
	assert_false(full_result.succeeded)
	assert_eq(full_result.error_code, SurvivorSystem.ERROR_INVALID_LINEUP)
	assert_false(duplicate_result.succeeded)
	assert_eq(duplicate_result.error_code, SurvivorSystem.ERROR_INVALID_LINEUP)


func _create_session() -> GameSession:
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(704), session.get_last_error())
	return session
