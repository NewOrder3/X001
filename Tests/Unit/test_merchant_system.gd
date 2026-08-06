extends "res://Tests/TestCase.gd"


func test_merchant_offers_initialize_stock_from_definition() -> void:
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(1000), session.get_last_error())
	assert_eq(session.get_merchants().size(), 1)
	assert_eq(session.get_merchant_stock(&"offer_fresh_water"), 5)
	assert_eq(session.get_merchant_stock(&"offer_grilled_fish"), 5)
	assert_eq(session.get_merchant_stock(&"offer_wood_bundle"), 3)


func test_buy_spends_cost_atomically_and_emits_signal() -> void:
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(1001), session.get_last_error())
	var purchased: Array[StringName] = []
	session.get_merchant_system().merchant_purchase_completed.connect(
		func(offer_id: StringName, _item_id: StringName, _amount: int) -> void:
			purchased.append(offer_id)
	)

	var result: CommandResult = session.execute_command(BuyMerchantItemCommand.new(&"offer_fresh_water"))

	assert_true(result.succeeded, result.message)
	assert_eq(session.get_item_amount(&"item_wood"), 8)
	assert_eq(session.get_item_amount(&"item_fresh_water"), 1)
	assert_eq(session.get_merchant_stock(&"offer_fresh_water"), 4)
	assert_eq(purchased, [&"offer_fresh_water"])


func test_failed_purchase_does_not_mutate_inventory_or_stock() -> void:
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(1002), session.get_last_error())
	assert_true(session.get_inventory_system().spend_cost(session.get_state().inventory_state, {&"item_wood": 9}))
	assert_eq(session.get_item_amount(&"item_wood"), 1)

	var result: CommandResult = session.execute_command(BuyMerchantItemCommand.new(&"offer_fresh_water"))

	assert_false(result.succeeded)
	assert_eq(result.error_code, MerchantSystem.ERROR_INSUFFICIENT_RESOURCES)
	assert_eq(session.get_item_amount(&"item_wood"), 1)
	assert_eq(session.get_item_amount(&"item_fresh_water"), 0)
	assert_eq(session.get_merchant_stock(&"offer_fresh_water"), 5)
	var unknown_result: CommandResult = session.execute_command(BuyMerchantItemCommand.new(&"offer_missing"))
	assert_false(unknown_result.succeeded)
	assert_eq(unknown_result.error_code, MerchantSystem.ERROR_UNKNOWN_OFFER)


func test_stock_exhaustion_and_capacity_are_enforced() -> void:
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(1003), session.get_last_error())
	for _index: int in range(5):
		assert_true(session.execute_command(BuyMerchantItemCommand.new(&"offer_fresh_water")).succeeded)
	assert_eq(session.get_item_amount(&"item_wood"), 0)
	assert_eq(session.get_merchant_stock(&"offer_fresh_water"), 0)
	var sold_out_result: CommandResult = session.execute_command(BuyMerchantItemCommand.new(&"offer_fresh_water"))
	assert_false(sold_out_result.succeeded)
	assert_eq(sold_out_result.error_code, MerchantSystem.ERROR_OUT_OF_STOCK)

	var full_session: GameSession = GameSession.new()
	assert_true(full_session.create_new_game(1004), full_session.get_last_error())
	assert_true(full_session.execute_command(GatherResourcesCommand.new(&"item_fresh_water", 20)).succeeded)
	var wood_before: int = full_session.get_item_amount(&"item_wood")
	var full_result: CommandResult = full_session.execute_command(BuyMerchantItemCommand.new(&"offer_fresh_water"))
	assert_false(full_result.succeeded)
	assert_eq(full_result.error_code, MerchantSystem.ERROR_INVENTORY_FULL)
	assert_eq(full_session.get_item_amount(&"item_wood"), wood_before)
	assert_eq(full_session.get_merchant_stock(&"offer_fresh_water"), 5)


func test_wood_bundle_offer_purchases_multiple_items() -> void:
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(1007), session.get_last_error())
	assert_true(session.execute_command(GatherResourcesCommand.new(&"item_raw_fish", 3)).succeeded)

	var result: CommandResult = session.execute_command(BuyMerchantItemCommand.new(&"offer_wood_bundle"))

	assert_true(result.succeeded, result.message)
	assert_eq(session.get_item_amount(&"item_raw_fish"), 0)
	assert_eq(session.get_item_amount(&"item_wood"), 15)
	assert_eq(session.get_merchant_stock(&"offer_wood_bundle"), 2)


func test_merchant_state_round_trips_and_v9_migration() -> void:
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(1005), session.get_last_error())
	assert_true(session.execute_command(BuyMerchantItemCommand.new(&"offer_fresh_water")).succeeded)
	var service: SaveService = SaveService.new()
	service.set_active_state(session.get_state())
	assert_true(service.save_game(&"merchant_state_test", 1_710_000_000))
	var loaded_state: GameState = service.load_game(&"merchant_state_test")
	assert_not_null(loaded_state)
	if loaded_state == null:
		return
	assert_eq(loaded_state.merchant_state.stock_remaining.get(&"offer_fresh_water", 0), 4)
	assert_eq(loaded_state.inventory_state.item_amounts.get(&"item_fresh_water", 0), 1)
	var restored_session: GameSession = GameSession.new()
	assert_true(restored_session.load_state_at(loaded_state, 1_710_000_000), restored_session.get_last_error())
	assert_eq(restored_session.get_merchant_stock(&"offer_fresh_water"), 4)

	var v9_data: Dictionary = {
		"save_version": 9,
		"world_seed": 1006,
		"game_state": {"world_seed": 1006, "progression_state": {"raft_level": 1}},
	}
	var migrate_service: SaveService = SaveService.new()
	var migrated_data: Dictionary = migrate_service.migrate(v9_data)
	assert_eq(int(migrated_data.get("save_version", 0)), SaveService.CURRENT_SAVE_VERSION)
	var game_state_data: Dictionary = migrated_data.get("game_state", {}) as Dictionary
	var merchant_data: Dictionary = game_state_data.get("merchant_state", {}) as Dictionary
	assert_eq(merchant_data.get("stock_remaining", {}), {})
