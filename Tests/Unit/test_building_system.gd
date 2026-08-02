extends "res://Tests/TestCase.gd"


func test_place_building_spends_cost_and_creates_instance() -> void:
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(42), session.get_last_error())
	var result: CommandResult = session.execute_place_building(
		PlaceBuildingCommand.new(&"building_rain_collector", Vector2i(0, 0), 0)
	)
	assert_true(result.succeeded, result.message)
	assert_eq(session.get_item_amount(&"item_wood"), 7)
	assert_false(session.get_raft_state().grid.is_walkable(Vector2i(0, 0)))
	assert_eq(session.get_raft_state().building_instances.size(), 1)


func test_failed_placement_does_not_spend_resources() -> void:
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(42), session.get_last_error())
	var outside_result: CommandResult = session.execute_place_building(
		PlaceBuildingCommand.new(&"building_rain_collector", Vector2i(2, 0), 0)
	)
	assert_false(outside_result.succeeded)
	assert_eq(outside_result.error_code, &"invalid_placement")
	assert_eq(session.get_item_amount(&"item_wood"), 10)
	var first_result: CommandResult = session.execute_place_building(
		PlaceBuildingCommand.new(&"building_rain_collector", Vector2i(0, 0), 0)
	)
	assert_true(first_result.succeeded)
	var second_result: CommandResult = session.execute_place_building(
		PlaceBuildingCommand.new(&"building_rain_collector", Vector2i(0, 0), 0)
	)
	assert_false(second_result.succeeded)
	assert_eq(second_result.error_code, &"invalid_placement")
	assert_eq(session.get_item_amount(&"item_wood"), 7)


func test_insufficient_resources_and_unknown_building_are_rejected() -> void:
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(42), session.get_last_error())
	var state: RaftState = session.get_raft_state()
	assert_not_null(state)
	var first_result: CommandResult = session.execute_place_building(
		PlaceBuildingCommand.new(&"building_rain_collector", Vector2i(-1, -1), 0)
	)
	assert_true(first_result.succeeded)
	var second_result: CommandResult = session.execute_place_building(
		PlaceBuildingCommand.new(&"building_rain_collector", Vector2i(1, 1), 0)
	)
	assert_true(second_result.succeeded)
	var third_result: CommandResult = session.execute_place_building(
		PlaceBuildingCommand.new(&"building_rain_collector", Vector2i(0, 1), 0)
	)
	assert_true(third_result.succeeded)
	assert_eq(session.get_item_amount(&"item_wood"), 1)
	var insufficient_result: CommandResult = session.execute_place_building(
		PlaceBuildingCommand.new(&"building_rain_collector", Vector2i(1, 0), 0)
	)
	assert_false(insufficient_result.succeeded)
	assert_eq(insufficient_result.error_code, &"insufficient_resources")
	var unknown_result: CommandResult = session.execute_place_building(
		PlaceBuildingCommand.new(&"building_missing", Vector2i(0, -1), 0)
	)
	assert_false(unknown_result.succeeded)
	assert_eq(unknown_result.error_code, &"unknown_building")


func test_built_instance_and_inventory_survive_save_load() -> void:
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(42), session.get_last_error())
	var result: CommandResult = session.execute_place_building(
		PlaceBuildingCommand.new(&"building_rain_collector", Vector2i(1, -1), 0)
	)
	assert_true(result.succeeded, result.message)
	var save_service: SaveService = SaveService.new()
	save_service.set_active_state(session.get_state())
	assert_true(save_service.save_game(&"building_slice_test"))
	var loaded_state: GameState = save_service.load_game(&"building_slice_test")
	assert_not_null(loaded_state)
	if loaded_state == null:
		return
	assert_eq(loaded_state.inventory_state.item_amounts.get(&"item_wood", 0), 7)
	assert_eq(loaded_state.raft_state.building_instances.size(), 1)
	assert_false(loaded_state.raft_state.grid.is_walkable(Vector2i(1, -1)))
