extends "res://Tests/TestCase.gd"


func test_new_game_exposes_only_the_first_ordered_goal() -> void:
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(1100), session.get_last_error())
	var quests: Array[QuestDefinition] = session.get_active_quests()
	assert_eq(quests.size(), 1)
	assert_eq(quests[0].id, &"quest_first_shelter")
	assert_eq(session.get_current_quest().id, &"quest_first_shelter")


func test_goal_chain_advances_after_fresh_water_is_produced_and_used() -> void:
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(1101), session.get_last_error())
	assert_true(session.execute_command(
		PlaceBuildingCommand.new(&"building_rain_collector", Vector2i(0, 0), 0)
	).succeeded)
	assert_true(session.get_quest_system().is_completed(session.get_state(), &"quest_first_shelter"))
	assert_eq(session.get_current_quest().id, &"quest_first_drink")

	for _second: int in range(50):
		session.advance_simulation(1.0)
	assert_true(session.get_item_amount(&"item_fresh_water") >= 1)
	assert_true(session.execute_command(UseFoodCommand.new(&"item_fresh_water")).succeeded)
	assert_true(session.get_quest_system().is_completed(session.get_state(), &"quest_first_drink"))
	assert_eq(session.get_current_quest().id, &"quest_first_sail")
	assert_eq(session.get_quest_state().used_item_counts.get(&"item_fresh_water", 0), 1)


func test_first_western_voyage_guarantees_rescue_and_advances_chain() -> void:
	var session: GameSession = _create_session_at_crew_goal(1102)
	assert_true(session.get_survivor_state().pending_recruitment_ids.has(&"survivor_bo"))
	assert_true(session.execute_command(RecruitSurvivorCommand.new(&"survivor_bo")).succeeded)
	assert_true(session.get_quest_system().is_completed(session.get_state(), &"quest_first_crew"))
	assert_eq(session.get_current_quest().id, &"quest_first_expand")
	assert_true(session.execute_command(GatherResourcesCommand.new(&"item_wood", 6)).succeeded)
	assert_true(session.execute_command(UpgradeRaftCommand.new()).succeeded)
	assert_true(session.get_quest_system().is_completed(session.get_state(), &"quest_first_expand"))
	assert_eq(session.get_current_quest().id, &"quest_first_boss")


func test_boss_goal_records_defeat_only_after_prior_goals() -> void:
	var session: GameSession = _create_session_at_crew_goal(1103)
	assert_true(session.execute_command(RecruitSurvivorCommand.new(&"survivor_bo")).succeeded)
	assert_true(session.execute_command(GatherResourcesCommand.new(&"item_wood", 6)).succeeded)
	assert_true(session.execute_command(UpgradeRaftCommand.new()).succeeded)
	assert_true(session.get_survivor_system().offer_recruitment(session.get_survivor_state(), &"survivor_marin"))
	assert_true(session.execute_command(RecruitSurvivorCommand.new(&"survivor_marin")).succeeded)
	assert_true(session.execute_command(SetLineupCommand.new([&"survivor_marin"])).succeeded)

	assert_true(session.execute_command(StartBattleCommand.new(&"boss_tutorial_sea_beast")).succeeded)
	assert_true(session.execute_command(BattleActionCommand.new(&"survivor_marin", true)).succeeded)
	while session.get_battle_state().status == BattleState.Status.ACTIVE:
		assert_true(session.execute_command(BattleActionCommand.new(&"survivor_marin", false)).succeeded)

	assert_true(session.get_battle_state().did_win)
	assert_true(session.get_quest_system().is_completed(session.get_state(), &"quest_first_boss"))
	assert_true(session.get_quest_state().defeated_boss_ids.has(&"boss_tutorial_sea_beast"))
	assert_true(session.get_active_quests().is_empty())


func test_quest_state_round_trips_and_v10_migration() -> void:
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(1104), session.get_last_error())
	assert_true(session.execute_command(
		PlaceBuildingCommand.new(&"building_rain_collector", Vector2i(0, 0), 0)
	).succeeded)
	assert_true(session.get_quest_system().is_completed(session.get_state(), &"quest_first_shelter"))
	var service: SaveService = SaveService.new()
	service.set_active_state(session.get_state())
	assert_true(service.save_game(&"quest_state_test", 1_710_000_000))
	var loaded_state: GameState = service.load_game(&"quest_state_test")
	assert_not_null(loaded_state)
	if loaded_state == null:
		return
	assert_true(loaded_state.quest_state.completed_quest_ids.has(&"quest_first_shelter"))
	assert_eq(loaded_state.quest_state.used_item_counts, {})
	var restored_session: GameSession = GameSession.new()
	assert_true(restored_session.load_state_at(loaded_state, 1_710_000_000), restored_session.get_last_error())
	assert_eq(restored_session.get_current_quest().id, &"quest_first_drink")

	var v10_data: Dictionary = {
		"save_version": 10,
		"world_seed": 1105,
		"game_state": {"world_seed": 1105, "progression_state": {"raft_level": 1}},
	}
	var migrate_service: SaveService = SaveService.new()
	var migrated_data: Dictionary = migrate_service.migrate(v10_data)
	assert_eq(int(migrated_data.get("save_version", 0)), SaveService.CURRENT_SAVE_VERSION)
	var game_state_data: Dictionary = migrated_data.get("game_state", {}) as Dictionary
	var quest_data: Dictionary = game_state_data.get("quest_state", {}) as Dictionary
	assert_eq(quest_data.get("completed_quest_ids", []), [])
	assert_eq(quest_data.get("defeated_boss_ids", []), [])
	assert_eq(quest_data.get("used_item_counts", {}), {})


func _create_session_at_crew_goal(seed: int) -> GameSession:
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(seed), session.get_last_error())
	assert_true(session.execute_command(
		PlaceBuildingCommand.new(&"building_rain_collector", Vector2i(0, 0), 0)
	).succeeded)
	for _second: int in range(50):
		session.advance_simulation(1.0)
	assert_true(session.execute_command(UseFoodCommand.new(&"item_fresh_water")).succeeded)
	assert_true(session.execute_command(
		PlaceBuildingCommand.new(&"building_rudder", Vector2i(1, 0), 0)
	).succeeded)
	assert_true(session.execute_command(ExploreRegionCommand.new(&"region_west_shoals")).succeeded)
	assert_eq(session.get_current_quest().id, &"quest_first_crew")
	return session
