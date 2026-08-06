extends "res://Tests/TestCase.gd"


func test_new_game_starts_at_raft_level_one_with_three_by_three_deck() -> void:
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(900), session.get_last_error())
	assert_eq(session.get_raft_level(), 1)
	assert_eq(session.get_raft_state().grid.get_deck_size(), Vector2i(3, 3))
	assert_eq(session.get_item_amount(&"item_wood"), 10)
	assert_false(session.is_exploration_unlocked())


func test_raft_upgrade_spends_wood_expands_deck_and_emits_signal() -> void:
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(901), session.get_last_error())
	var upgraded_levels: Array[int] = []
	session.get_progression_system().raft_upgraded.connect(
		func(new_level: int) -> void:
			upgraded_levels.append(new_level)
	)

	var first_result: CommandResult = session.execute_command(UpgradeRaftCommand.new())
	assert_true(first_result.succeeded, first_result.message)
	assert_eq(session.get_raft_level(), 2)
	assert_eq(session.get_raft_state().grid.get_deck_size(), Vector2i(4, 4))
	assert_eq(session.get_item_amount(&"item_wood"), 2)

	assert_true(session.execute_command(GatherResourcesCommand.new(&"item_wood", 20)).succeeded)
	var second_result: CommandResult = session.execute_command(UpgradeRaftCommand.new())
	assert_true(second_result.succeeded, second_result.message)
	assert_eq(session.get_raft_level(), 3)
	assert_eq(session.get_raft_state().grid.get_deck_size(), Vector2i(5, 6))
	assert_eq(upgraded_levels, [2, 3])

	var third_result: CommandResult = session.execute_command(UpgradeRaftCommand.new())
	assert_false(third_result.succeeded)
	assert_eq(third_result.error_code, ProgressionSystem.ERROR_MAX_RAFT_LEVEL)
	assert_eq(session.get_raft_level(), 3)


func test_insufficient_resources_reject_without_mutation() -> void:
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(902), session.get_last_error())
	assert_true(
		session.get_inventory_system().spend_cost(session.get_state().inventory_state, {&"item_wood": 8})
	)
	assert_eq(session.get_item_amount(&"item_wood"), 2)

	var result: CommandResult = session.execute_command(UpgradeRaftCommand.new())

	assert_false(result.succeeded)
	assert_eq(result.error_code, ProgressionSystem.ERROR_INSUFFICIENT_RESOURCES)
	assert_eq(session.get_raft_level(), 1)
	assert_eq(session.get_raft_state().grid.get_deck_size(), Vector2i(3, 3))
	assert_eq(session.get_item_amount(&"item_wood"), 2)


func test_exploration_unlock_is_data_driven_and_requires_rudder() -> void:
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(903), session.get_last_error())
	assert_false(session.is_unlock_available(&"unlock_exploration"))
	assert_false(session.is_unlock_available(&"unlock_missing"))
	assert_false(session.is_exploration_unlocked())

	assert_true(session.execute_command(
		PlaceBuildingCommand.new(&"building_rudder", Vector2i.ZERO, 0)
	).succeeded)

	assert_true(session.is_unlock_available(&"unlock_exploration"))
	assert_true(session.is_exploration_unlocked())
	var explore_result: CommandResult = session.execute_command(ExploreRegionCommand.new(&"region_west_shoals"))
	assert_true(explore_result.succeeded, explore_result.message)


func test_raft_progression_round_trips_through_save_data() -> void:
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(904), session.get_last_error())
	assert_true(session.execute_command(UpgradeRaftCommand.new()).succeeded)
	assert_eq(session.get_raft_level(), 2)

	var service: SaveService = SaveService.new()
	service.set_active_state(session.get_state())
	assert_true(service.save_game(&"progression_raft_test", 1_710_000_000))
	var loaded_state: GameState = service.load_game(&"progression_raft_test")
	assert_not_null(loaded_state)
	if loaded_state == null:
		return
	assert_eq(loaded_state.progression_state.raft_level, 2)
	assert_eq(loaded_state.raft_state.grid.get_deck_size(), Vector2i(4, 4))
	var restored_session: GameSession = GameSession.new()
	assert_true(restored_session.load_state_at(loaded_state, 1_710_000_000), restored_session.get_last_error())
	assert_eq(restored_session.get_raft_level(), 2)


func test_migrate_v8_adds_raft_level_defaults() -> void:
	var v8_data: Dictionary = {
		"save_version": 8,
		"world_seed": 905,
		"game_state": {
			"world_seed": 905,
			"progression_state": {},
		},
	}
	var service: SaveService = SaveService.new()
	var migrated_data: Dictionary = service.migrate(v8_data)
	assert_eq(int(migrated_data.get("save_version", 0)), SaveService.CURRENT_SAVE_VERSION)
	var game_state_data: Dictionary = migrated_data.get("game_state", {}) as Dictionary
	var progression_data: Dictionary = game_state_data.get("progression_state", {}) as Dictionary
	assert_eq(int(progression_data.get("raft_level", 0)), 1)
