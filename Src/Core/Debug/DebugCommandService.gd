class_name DebugCommandService
extends RefCounted

func new_game(session: GameSession, seed: int) -> CommandResult:
	var system: SessionCommandSystem = SessionCommandSystem.new()
	return system.execute(session, CreateNewGameCommand.new(seed))
