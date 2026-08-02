class_name BattleRoot
extends Node

var _session: GameSession = null
var _context: Variant = null

func bind_context(session: GameSession, context: Variant) -> void:
	_session = session
	_context = context


func get_session() -> GameSession:
	return _session
