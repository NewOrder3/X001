extends "res://Tests/TestCase.gd"

var _rejected_command_type: StringName = &""
var _rejection_error_code: StringName = &""
var _rejection_count: int = 0


func test_gather_command_returns_system_result_and_rejection_event() -> void:
	var session: GameSession = _create_session()
	_bind_rejection_event(session)

	var success_result: CommandResult = session.execute_command(
		GatherResourcesCommand.new(&"item_raw_fish", 1)
	)
	var failure_result: CommandResult = session.execute_command(
		GatherResourcesCommand.new(&"item_missing", 1)
	)

	assert_true(success_result.succeeded, success_result.message)
	assert_eq(session.get_item_amount(&"item_raw_fish"), 1)
	assert_false(failure_result.succeeded)
	assert_eq(failure_result.error_code, &"unknown_item")
	assert_eq(_rejection_count, 1)
	assert_eq(_rejected_command_type, &"gather_resources")
	assert_eq(_rejection_error_code, &"unknown_item")


func test_use_food_command_returns_system_result_and_rejection_event() -> void:
	var session: GameSession = _create_session()
	session.get_survival_state().supply = 50.0
	_bind_rejection_event(session)
	assert_true(session.execute_command(GatherResourcesCommand.new(&"item_fresh_water", 1)).succeeded)

	var success_result: CommandResult = session.execute_command(UseFoodCommand.new(&"item_fresh_water"))
	var failure_result: CommandResult = session.execute_command(UseFoodCommand.new(&"item_fresh_water"))

	assert_true(success_result.succeeded, success_result.message)
	assert_eq(session.get_survival_state().supply, 60.0)
	assert_false(failure_result.succeeded)
	assert_eq(failure_result.error_code, &"insufficient_resources")
	assert_eq(_rejection_count, 1)
	assert_eq(_rejected_command_type, &"use_food")
	assert_eq(_rejection_error_code, &"insufficient_resources")


func test_set_production_enabled_command_returns_system_result_and_rejection_event() -> void:
	var session: GameSession = _create_session()
	_bind_rejection_event(session)
	var place_result: CommandResult = session.execute_command(
		PlaceBuildingCommand.new(&"building_rain_collector", Vector2i.ZERO, 0)
	)
	assert_true(place_result.succeeded, place_result.message)

	var success_result: CommandResult = session.execute_command(
		SetProductionEnabledCommand.new(&"instance_rain_collector_1", false)
	)
	var failure_result: CommandResult = session.execute_command(
		SetProductionEnabledCommand.new(&"instance_missing", true)
	)

	assert_true(success_result.succeeded, success_result.message)
	var production: ProductionInstance = session.get_production_system().get_instance(
		session.get_state(),
		&"instance_rain_collector_1",
	)
	assert_not_null(production)
	if production != null:
		assert_false(production.is_enabled)
	assert_false(failure_result.succeeded)
	assert_eq(failure_result.error_code, &"not_a_production_facility")
	assert_eq(_rejection_count, 1)
	assert_eq(_rejected_command_type, &"set_production_enabled")
	assert_eq(_rejection_error_code, &"not_a_production_facility")


func test_buy_merchant_item_command_returns_system_result_and_rejection_event() -> void:
	var session: GameSession = _create_session()
	_bind_rejection_event(session)

	var success_result: CommandResult = session.execute_command(BuyMerchantItemCommand.new(&"offer_fresh_water"))
	assert_true(success_result.succeeded, success_result.message)
	assert_eq(session.get_item_amount(&"item_wood"), 8)
	assert_eq(session.get_item_amount(&"item_fresh_water"), 1)
	assert_true(session.get_inventory_system().spend_cost(session.get_state().inventory_state, {&"item_wood": 8}))

	var failure_result: CommandResult = session.execute_command(BuyMerchantItemCommand.new(&"offer_fresh_water"))
	assert_false(failure_result.succeeded)
	assert_eq(failure_result.error_code, MerchantSystem.ERROR_INSUFFICIENT_RESOURCES)
	assert_eq(_rejection_count, 1)
	assert_eq(_rejected_command_type, &"buy_merchant_item")
	assert_eq(_rejection_error_code, MerchantSystem.ERROR_INSUFFICIENT_RESOURCES)


func _create_session() -> GameSession:
	var session: GameSession = GameSession.new()
	var result: CommandResult = session.execute_command(CreateNewGameCommand.new(50))
	assert_true(result.succeeded, result.message)
	return session


func _bind_rejection_event(session: GameSession) -> void:
	_rejected_command_type = &""
	_rejection_error_code = &""
	_rejection_count = 0
	session.get_session_events().command_rejected.connect(_on_command_rejected)


func _on_command_rejected(command_type: StringName, error_code: StringName) -> void:
	_rejected_command_type = command_type
	_rejection_error_code = error_code
	_rejection_count += 1
