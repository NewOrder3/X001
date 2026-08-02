class_name GameRoot
extends Node

var _session: GameSession = null

func bind_session(session: GameSession) -> void:
	_session = session


func get_session() -> GameSession:
	return _session
