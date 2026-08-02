extends GutTest

func test_save_load_restores_raft_occupancy_and_instances() -> void:
	var state: GameState = GameState.new(2468)
	var instance: BuildingInstance = BuildingInstance.new(&"instance_collector", &"building_rain_collector", Vector2i(0, 0))
	assert_true(state.raft_state.add_building_instance(instance, Vector2i.ONE))
	var service: SaveService = SaveService.new()
	service.set_active_state(state)
	assert_true(service.save_game(&"save_service_test"))
	var loaded_state: GameState = service.load_game(&"save_service_test")
	assert_not_null(loaded_state)
	assert_eq(loaded_state.world_seed, 2468)
	assert_false(loaded_state.raft_state.grid.is_walkable(Vector2i(0, 0)))
	assert_true(loaded_state.raft_state.building_instances.has(&"instance_collector"))
