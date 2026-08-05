class_name DebugCommandService
extends RefCounted

func new_game(session: GameSession, world_seed: int) -> CommandResult:
	if session == null:
		return CommandResult.failure(&"invalid_session", "Cannot create a game without a GameSession.")
	return session.execute_command(CreateNewGameCommand.new(world_seed))
