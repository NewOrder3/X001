class_name GameRoot
extends Node

@onready var _build_view: RaftBuildView = $RaftBuildView
@onready var _build_panel: RaftBuildPanel = $UIRoot/HUDLayer/RaftBuildPanel

var _session: GameSession = null


func _ready() -> void:
	_bind_views()


func bind_session(session: GameSession) -> void:
	_session = session
	_bind_views()


func get_session() -> GameSession:
	return _session


func _bind_views() -> void:
	if not is_node_ready() or _session == null:
		return
	_build_view.bind_session(_session)
	_build_panel.bind_session(_session)
