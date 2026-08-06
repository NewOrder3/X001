extends "res://Tests/TestCase.gd"


func test_gathering_respects_item_capacity() -> void:
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(11), session.get_last_error())
	assert_true(session.execute_gather_resources(GatherResourcesCommand.new(&"item_raw_fish", 10)).succeeded)
	var overflow: CommandResult = session.execute_gather_resources(GatherResourcesCommand.new(&"item_raw_fish", 1))
	assert_false(overflow.succeeded)
	assert_eq(overflow.error_code, &"inventory_full")
	assert_eq(session.get_item_amount(&"item_raw_fish"), 10)


func test_production_batches_cycles_and_consumes_inputs() -> void:
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(12), session.get_last_error())
	assert_true(session.execute_gather_resources(GatherResourcesCommand.new(&"item_wood", 4)).succeeded)
	assert_true(session.execute_gather_resources(GatherResourcesCommand.new(&"item_raw_fish", 2)).succeeded)
	var build_result: CommandResult = session.execute_place_building(
		PlaceBuildingCommand.new(&"building_campfire", Vector2i(0, 0), 0)
	)
	assert_true(build_result.succeeded, build_result.message)
	_advance_seconds(session, 40)
	assert_eq(session.get_item_amount(&"item_raw_fish"), 0)
	assert_eq(session.get_item_amount(&"item_grilled_fish"), 2)


func test_disabled_facility_and_full_output_stall_without_losing_progress() -> void:
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(13), session.get_last_error())
	var build_result: CommandResult = session.execute_place_building(
		PlaceBuildingCommand.new(&"building_rain_collector", Vector2i(0, 0), 0)
	)
	assert_true(build_result.succeeded, build_result.message)
	_advance_seconds(session, 10)
	var instance_id: StringName = &"instance_rain_collector_1"
	var stopped: CommandResult = session.execute_set_production_enabled(SetProductionEnabledCommand.new(instance_id, false))
	assert_true(stopped.succeeded, stopped.message)
	_advance_seconds(session, 30)
	assert_eq(session.get_item_amount(&"item_fresh_water"), 0)
	var started: CommandResult = session.execute_set_production_enabled(SetProductionEnabledCommand.new(instance_id, true))
	assert_true(started.succeeded, started.message)
	_advance_seconds(session, 20)
	assert_eq(session.get_item_amount(&"item_fresh_water"), 1)
	assert_true(session.execute_gather_resources(GatherResourcesCommand.new(&"item_fresh_water", 19)).succeeded)
	_advance_seconds(session, 30)
	var production: ProductionInstance = session.get_production_system().get_instance(session.get_state(), instance_id)
	assert_eq(production.stall_reason, ProductionInstance.StallReason.OUTPUT_CAPACITY_REACHED)
	assert_eq(session.get_item_amount(&"item_fresh_water"), 20)


func test_food_use_and_repair_station_restore_survival_values() -> void:
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(14), session.get_last_error())
	session.get_survival_state().supply = 50.0
	assert_true(session.execute_gather_resources(GatherResourcesCommand.new(&"item_fresh_water", 1)).succeeded)
	assert_true(session.execute_use_food(UseFoodCommand.new(&"item_fresh_water")).succeeded)
	assert_eq(session.get_survival_state().supply, 60.0)
	var build_result: CommandResult = session.execute_place_building(
		PlaceBuildingCommand.new(&"building_repair_station", Vector2i(0, 0), 0)
	)
	assert_true(build_result.succeeded, build_result.message)
	session.get_survival_state().durability = 0.0
	_advance_seconds(session, 5)
	assert_eq(session.get_survival_state().durability, 0.5)


func test_production_progress_survives_save_load() -> void:
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(15), session.get_last_error())
	assert_true(session.execute_place_building(PlaceBuildingCommand.new(&"building_rain_collector", Vector2i(0, 0), 0)).succeeded)
	_advance_seconds(session, 10)
	var save_service: SaveService = SaveService.new()
	save_service.set_active_state(session.get_state())
	assert_true(save_service.save_game(&"production_progress_test"))
	var loaded_state: GameState = save_service.load_game(&"production_progress_test")
	assert_not_null(loaded_state)
	if loaded_state == null:
		return
	var production: ProductionInstance = loaded_state.production_state.instances.get(&"instance_rain_collector_1") as ProductionInstance
	assert_not_null(production)
	if production != null:
		assert_eq(production.progress_seconds, 10.0)


func test_thirty_minute_run_keeps_inventory_bounded_and_saveable() -> void:
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(16), session.get_last_error())
	assert_true(session.execute_gather_resources(GatherResourcesCommand.new(&"item_wood", 4)).succeeded)
	assert_true(session.execute_gather_resources(GatherResourcesCommand.new(&"item_raw_fish", 10)).succeeded)
	assert_true(session.execute_place_building(PlaceBuildingCommand.new(&"building_rain_collector", Vector2i(0, 0), 0)).succeeded)
	assert_true(session.execute_place_building(PlaceBuildingCommand.new(&"building_campfire", Vector2i(1, 0), 0)).succeeded)
	_advance_seconds(session, 30 * 60)
	for amount: int in session.get_state().inventory_state.item_amounts.values():
		assert_true(amount >= 0)
	assert_eq(session.get_item_amount(&"item_fresh_water"), 20)
	assert_eq(session.get_item_amount(&"item_grilled_fish"), 10)
	var save_service: SaveService = SaveService.new()
	save_service.set_active_state(session.get_state())
	assert_true(save_service.save_game(&"production_long_run_test"))
	var loaded_state: GameState = save_service.load_game(&"production_long_run_test")
	assert_not_null(loaded_state)
	if loaded_state != null:
		assert_eq(loaded_state.inventory_state.item_amounts.get(&"item_fresh_water", 0), 20)
		assert_eq(loaded_state.inventory_state.item_amounts.get(&"item_grilled_fish", 0), 10)


func test_desalinator_converts_seawater_into_fresh_water() -> void:
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(17), session.get_last_error())
	assert_true(session.execute_gather_resources(GatherResourcesCommand.new(&"item_seawater", 2)).succeeded)
	assert_true(session.execute_place_building(
		PlaceBuildingCommand.new(&"building_desalinator", Vector2i(0, 0), 0)
	).succeeded)

	_advance_seconds(session, 25)

	assert_eq(session.get_item_amount(&"item_seawater"), 0)
	assert_eq(session.get_item_amount(&"item_fresh_water"), 1)


func test_fishing_net_produces_raw_fish_without_input() -> void:
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(18), session.get_last_error())
	assert_true(session.execute_place_building(
		PlaceBuildingCommand.new(&"building_fishing_net", Vector2i(0, 0), 0)
	).succeeded)

	_advance_seconds(session, 30)
	assert_eq(session.get_item_amount(&"item_raw_fish"), 1)
	_advance_seconds(session, 60)
	assert_eq(session.get_item_amount(&"item_raw_fish"), 3)


func test_storage_rack_expands_storage_capacity() -> void:
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(19), session.get_last_error())
	assert_true(session.execute_place_building(
		PlaceBuildingCommand.new(&"building_storage_rack", Vector2i(0, 0), 0)
	).succeeded)
	var state: GameState = session.get_state()
	assert_eq(session.get_inventory_system().get_capacity(state, &"item_wood"), 119)
	assert_eq(session.get_inventory_system().get_capacity(state, &"item_raw_fish"), 20)
	assert_eq(session.get_inventory_system().get_capacity(state, &"item_grilled_fish"), 20)
	assert_eq(session.get_inventory_system().get_capacity(state, &"item_fresh_water"), 20)


func _advance_seconds(session: GameSession, seconds: int) -> void:
	for _second: int in range(seconds):
		session.advance_simulation(1.0)
