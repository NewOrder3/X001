extends "res://Tests/TestCase.gd"


func test_new_game_starts_in_starting_region_with_three_adjacent_destinations() -> void:
	var session: GameSession = _create_session(600)
	var world_state: WorldState = session.get_world_state()

	assert_eq(world_state.current_region_id, &"region_starting_sea")
	assert_true(world_state.is_discovered(&"region_starting_sea"))
	assert_eq(session.get_reachable_regions().size(), 3)
	assert_true(session.is_exploration_unlocked())


func test_rudder_is_required_before_exploration() -> void:
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(599), session.get_last_error())
	var result: CommandResult = session.execute_command(ExploreRegionCommand.new(&"region_west_shoals"))
	assert_false(result.succeeded)
	assert_eq(result.error_code, ExplorationSystem.ERROR_EXPLORATION_LOCKED)
	assert_eq(session.get_survival_state().stamina, 10)


func test_non_adjacent_or_unaffordable_voyage_does_not_mutate_world_state() -> void:
	var session: GameSession = _create_session(601)
	var world_state: WorldState = session.get_world_state()
	var non_adjacent_result: CommandResult = session.execute_command(
		ExploreRegionCommand.new(&"region_starting_sea")
	)
	assert_false(non_adjacent_result.succeeded)
	assert_eq(non_adjacent_result.error_code, ExplorationSystem.ERROR_NOT_ADJACENT)
	assert_eq(world_state.current_region_id, &"region_starting_sea")
	assert_eq(session.get_survival_state().stamina, 10)

	session.get_survival_state().stamina = 0
	var stamina_result: CommandResult = session.execute_command(
		ExploreRegionCommand.new(&"region_west_shoals")
	)
	assert_false(stamina_result.succeeded)
	assert_eq(stamina_result.error_code, SurvivalSystem.ERROR_INSUFFICIENT_STAMINA)
	assert_eq(world_state.current_region_id, &"region_starting_sea")
	assert_false(world_state.is_discovered(&"region_west_shoals"))


func test_same_seed_and_state_resolve_the_same_encounter() -> void:
	var first: GameSession = _create_session(602)
	var second: GameSession = _create_session(602)

	var first_command: CommandResult = first.execute_command(ExploreRegionCommand.new(&"region_west_shoals"))
	var second_command: CommandResult = second.execute_command(ExploreRegionCommand.new(&"region_west_shoals"))
	var first_result: ExplorationResult = first.get_last_exploration_result()
	var second_result: ExplorationResult = second.get_last_exploration_result()

	assert_true(first_command.succeeded, first_command.message)
	assert_true(second_command.succeeded, second_command.message)
	assert_not_null(first_result)
	assert_not_null(second_result)
	if first_result != null and second_result != null:
		assert_eq(first_result.encounter_id, second_result.encounter_id)
		assert_eq(first_result.reward_items, second_result.reward_items)
		assert_eq(first_result.durability_loss, second_result.durability_loss)


func test_consumed_encounter_is_not_resolved_twice_and_world_state_round_trips() -> void:
	var session: GameSession = _create_session(603)
	assert_true(session.execute_command(ExploreRegionCommand.new(&"region_west_shoals")).succeeded)
	var first_result: ExplorationResult = session.get_last_exploration_result()
	assert_not_null(first_result)
	assert_true(session.execute_command(ExploreRegionCommand.new(&"region_starting_sea")).succeeded)
	assert_true(session.execute_command(ExploreRegionCommand.new(&"region_west_shoals")).succeeded)
	var second_result: ExplorationResult = session.get_last_exploration_result()
	assert_not_null(second_result)
	if first_result != null and second_result != null:
		assert_false(first_result.encounter_id == second_result.encounter_id)

	var service: SaveService = SaveService.new()
	service.set_active_state(session.get_state())
	assert_true(service.save_game(&"exploration_world_state_test", 1_710_000_000))
	var loaded_state: GameState = service.load_game(&"exploration_world_state_test")
	assert_not_null(loaded_state)
	if loaded_state != null:
		assert_eq(loaded_state.world_state.current_region_id, &"region_west_shoals")
		assert_eq(loaded_state.world_state.discovered_region_ids, session.get_world_state().discovered_region_ids)
		assert_eq(loaded_state.world_state.consumed_encounter_keys, session.get_world_state().consumed_encounter_keys)


func test_storm_encounter_applies_durability_loss() -> void:
	var found_storm: bool = false
	for seed: int in range(1, 64):
		var session: GameSession = _create_session(seed)
		var command_result: CommandResult = session.execute_command(ExploreRegionCommand.new(&"region_north_mist"))
		var exploration_result: ExplorationResult = session.get_last_exploration_result()
		if command_result.succeeded and exploration_result != null and exploration_result.encounter_id == &"event_sudden_storm":
			found_storm = true
			assert_eq(exploration_result.durability_loss, 15.0)
			assert_eq(session.get_survival_state().durability, 85.0)
			break
	assert_true(found_storm, "Expected at least one fixed seed to resolve a storm.")


func _create_session(seed: int) -> GameSession:
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(seed), session.get_last_error())
	var rudder_result: CommandResult = session.execute_command(
		PlaceBuildingCommand.new(&"building_rudder", Vector2i.ZERO, 0)
	)
	assert_true(rudder_result.succeeded, rudder_result.message)
	return session
