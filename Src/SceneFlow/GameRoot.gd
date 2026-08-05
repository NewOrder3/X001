class_name GameRoot
extends Node

@onready var _build_view: RaftBuildView = $RaftBuildView
@onready var _build_panel: RaftBuildPanel = $UIRoot/HUDLayer/GameHudLayout/LeftPanelScroll/LeftPanelColumn/RaftBuildPanel
@onready var _survival_hud: SurvivalHUD = $UIRoot/HUDLayer/GameHudLayout/SurvivalHUD
@onready var _production_panel: ProductionPanel = $UIRoot/HUDLayer/GameHudLayout/LeftPanelScroll/LeftPanelColumn/ProductionPanel
@onready var _offline_settlement_panel: OfflineSettlementPanel = $UIRoot/WindowLayer/OfflineSettlementPanel

var _session: GameSession = null


func _ready() -> void:
	_bind_views()


func bind_session(session: GameSession) -> void:
	_session = session
	_bind_views()


func get_session() -> GameSession:
	return _session


func _process(delta: float) -> void:
	if _session != null:
		_session.advance_simulation(delta)


func _bind_views() -> void:
	if not is_node_ready() or _session == null:
		return
	_build_view.bind_session(_session)
	_build_panel.bind_session(_session)
	_survival_hud.bind_session(_session)
	_production_panel.bind_session(_session)
	_offline_settlement_panel.show_report(_session.get_last_offline_settlement_report())
