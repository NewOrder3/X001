extends "res://Tests/TestCase.gd"

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


func test_save_load_restores_inventory_amounts() -> void:
	var state: GameState = GameState.new(1357)
	state.inventory_state.item_amounts[&"item_wood"] = 7
	var service: SaveService = SaveService.new()
	service.set_active_state(state)
	assert_true(service.save_game(&"save_inventory_test"))
	var loaded_state: GameState = service.load_game(&"save_inventory_test")
	assert_not_null(loaded_state)
	assert_eq(loaded_state.inventory_state.item_amounts.get(&"item_wood", 0), 7)


func test_migrate_v1_adds_missing_state_sections() -> void:
	var source_state: GameState = GameState.new(2468)
	var v1_data: Dictionary = {
		"save_version": 1,
		"world_seed": 2468,
		"game_state": {
			"world_seed": 2468,
			"raft_state": source_state.raft_state.to_save_data(),
		},
	}
	var service: SaveService = SaveService.new()
	var migrated_data: Dictionary = service.migrate(v1_data)
	assert_eq(int(migrated_data.get("save_version", 0)), SaveService.CURRENT_SAVE_VERSION)
	var game_state_data: Dictionary = migrated_data.get("game_state", {}) as Dictionary
	assert_true(game_state_data.has("inventory_state"))
	assert_true(game_state_data.has("survivor_state"))
	assert_true(game_state_data.has("world_state"))
	assert_true(game_state_data.has("battle_state"))
	assert_true(game_state_data.has("progression_state"))
