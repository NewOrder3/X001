class_name SessionCommandSystem
extends RefCounted

## Handles session-level commands without exposing GameState to callers.

var events: SessionEvents


func _init(new_events: SessionEvents = null) -> void:
	if new_events == null:
		events = SessionEvents.new()
		return

	events = new_events


func execute(session: GameSession, command: GameCommand) -> CommandResult:
	if session == null:
		return _reject(command, &"invalid_session", GameText.get_text(&"message.session.invalid"))
	if command == null:
		return _reject(command, &"invalid_command", GameText.get_text(&"message.session.empty_command"))

	if command is CreateNewGameCommand:
		var create_command: CreateNewGameCommand = command as CreateNewGameCommand
		if not session.create_new_game(create_command.world_seed):
			return _reject(command, &"content_load_failed", session.get_last_error())
		events.new_game_created.emit(create_command.world_seed)
		return CommandResult.success(GameText.get_text(&"message.session.created"))
	if command is PlaceBuildingCommand:
		var place_command: PlaceBuildingCommand = command as PlaceBuildingCommand
		return _complete(command, session.execute_place_building(place_command))
	if command is UpgradeBuildingCommand:
		var upgrade_building_command: UpgradeBuildingCommand = command as UpgradeBuildingCommand
		return _complete(command, session.execute_upgrade_building(upgrade_building_command))
	if command is GatherResourcesCommand:
		var gather_command: GatherResourcesCommand = command as GatherResourcesCommand
		return _complete(command, session.execute_gather_resources(gather_command))
	if command is UseFoodCommand:
		var use_food_command: UseFoodCommand = command as UseFoodCommand
		return _complete(command, session.execute_use_food(use_food_command))
	if command is SetProductionEnabledCommand:
		var set_production_command: SetProductionEnabledCommand = command as SetProductionEnabledCommand
		return _complete(command, session.execute_set_production_enabled(set_production_command))
	if command is ExploreRegionCommand:
		var explore_command: ExploreRegionCommand = command as ExploreRegionCommand
		return _complete(command, session.execute_explore_region(explore_command))
	if command is RecruitSurvivorCommand:
		var recruit_command: RecruitSurvivorCommand = command as RecruitSurvivorCommand
		return _complete(command, session.execute_recruit_survivor(recruit_command))
	if command is UpgradeSurvivorCommand:
		var upgrade_command: UpgradeSurvivorCommand = command as UpgradeSurvivorCommand
		return _complete(command, session.execute_upgrade_survivor(upgrade_command))
	if command is SetLineupCommand:
		var lineup_command: SetLineupCommand = command as SetLineupCommand
		return _complete(command, session.execute_set_lineup(lineup_command))
	if command is StartBattleCommand:
		var start_battle_command: StartBattleCommand = command as StartBattleCommand
		var start_battle_result: CommandResult = _complete(command, session.execute_start_battle(start_battle_command))
		if start_battle_result.succeeded:
			events.battle_started.emit(start_battle_command.boss_id)
		return start_battle_result
	if command is BattleActionCommand:
		var battle_action_command: BattleActionCommand = command as BattleActionCommand
		return _complete(command, session.execute_battle_action(battle_action_command))
	if command is ReturnFromBattleCommand:
		var return_battle_result: CommandResult = _complete(command, session.execute_return_from_battle(command as ReturnFromBattleCommand))
		if return_battle_result.succeeded:
			events.battle_exited.emit()
		return return_battle_result

	return _reject(
		command,
		&"unsupported_command",
		GameText.format(&"message.session.unsupported_command", [String(command.get_command_type())]),
	)


func _reject(command: GameCommand, error_code: StringName, message: String) -> CommandResult:
	var command_type: StringName = &"unknown"
	if command != null:
		command_type = command.get_command_type()

	events.command_rejected.emit(command_type, error_code)
	return CommandResult.failure(error_code, message)


func _complete(command: GameCommand, result: CommandResult) -> CommandResult:
	if result != null and not result.succeeded:
		events.command_rejected.emit(command.get_command_type(), result.error_code)
	return result
