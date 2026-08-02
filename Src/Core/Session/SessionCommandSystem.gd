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
		return _reject(command, &"invalid_session", "Cannot execute a command without a GameSession.")
	if command == null:
		return _reject(command, &"invalid_command", "Cannot execute an empty command.")

	if command is CreateNewGameCommand:
		var create_command: CreateNewGameCommand = command as CreateNewGameCommand
		session.create_new_game(create_command.world_seed)
		events.new_game_created.emit(create_command.world_seed)
		return CommandResult.success("Created a new game session.")

	return _reject(
		command,
		&"unsupported_command",
		"No session handler is registered for command '%s'." % String(command.get_command_type()),
	)


func _reject(command: GameCommand, error_code: StringName, message: String) -> CommandResult:
	var command_type: StringName = &"unknown"
	if command != null:
		command_type = command.get_command_type()

	events.command_rejected.emit(command_type, error_code)
	return CommandResult.failure(error_code, message)
