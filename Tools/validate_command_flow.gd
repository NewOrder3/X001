extends SceneTree

var _received_world_seed: int = -1
var _rejected_command_type: StringName = &""
var _rejection_error_code: StringName = &""


func _init() -> void:
	var session: GameSession = GameSession.new()
	var system: SessionCommandSystem = SessionCommandSystem.new()
	system.events.new_game_created.connect(_on_new_game_created)
	system.events.command_rejected.connect(_on_command_rejected)

	var create_result: CommandResult = system.execute(session, CreateNewGameCommand.new(12345))
	if not create_result.succeeded or session.get_world_seed() != 12345:
		_fail("CreateNewGameCommand did not update the session.")
		return
	if _received_world_seed != 12345:
		_fail("new_game_created did not contain the new seed.")
		return

	var place_result: CommandResult = system.execute(
		session,
		PlaceBuildingCommand.new(&"building_rain_collector", Vector2i.ZERO, 0),
	)
	if not place_result.succeeded:
		_fail("PlaceBuildingCommand did not create a valid building.")
		return
	if session.get_item_amount(&"item_wood") != 7:
		_fail("PlaceBuildingCommand did not spend the configured cost.")
		return
	var rejected_result: CommandResult = system.execute(
		session,
		PlaceBuildingCommand.new(&"building_rain_collector", Vector2i.ZERO, 0),
	)
	if rejected_result.succeeded or rejected_result.error_code != &"invalid_placement":
		_fail("Overlapping placement did not report a clear failure.")
		return
	if session.get_item_amount(&"item_wood") != 7:
		_fail("Rejected command partially spent resources.")
		return
	if _rejected_command_type != &"place_building" or _rejection_error_code != &"invalid_placement":
		_fail("command_rejected payload was incorrect.")
		return

	print("Command and Signal validation passed.")
	quit(0)


func _on_new_game_created(world_seed: int) -> void:
	_received_world_seed = world_seed


func _on_command_rejected(command_type: StringName, error_code: StringName) -> void:
	_rejected_command_type = command_type
	_rejection_error_code = error_code


func _fail(message: String) -> void:
	printerr("COMMAND: %s" % message)
	quit(1)
