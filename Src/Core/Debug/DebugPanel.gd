class_name DebugPanel
extends Control

var _session: GameSession = null


func bind_session(session: GameSession) -> void:
	_session = session


func _ready() -> void:
	visible = OS.is_debug_build()


func _unhandled_key_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event.is_action_pressed(&"open_debug"):
		visible = not visible
		get_viewport().set_input_as_handled()


func create_new_game(world_seed: int) -> CommandResult:
	if _session == null:
		return CommandResult.failure(&"invalid_session", GameText.get_text(&"message.session.invalid"))
	return DebugCommandService.new().new_game(_session, world_seed)
