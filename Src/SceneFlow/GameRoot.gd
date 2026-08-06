class_name GameRoot
extends Node

@onready var _build_view: RaftBuildView = $RaftBuildView
@onready var _dynamic_ocean_map: DynamicOceanMap = $DynamicOceanMap
@onready var _hud_layout: GameHudLayout = $UIRoot/HUDLayer/GameHudLayout
@onready var _build_panel: RaftBuildPanel = $UIRoot/HUDLayer/GameHudLayout/LeftPanelScroll/LeftPanelColumn/RaftBuildPanel
@onready var _survival_hud: SurvivalHUD = $UIRoot/HUDLayer/GameHudLayout/SurvivalHUD
@onready var _production_panel: ProductionPanel = $UIRoot/HUDLayer/GameHudLayout/LeftPanelScroll/LeftPanelColumn/ProductionPanel
@onready var _world_map_panel: WorldMapPanel = $UIRoot/HUDLayer/GameHudLayout/LeftPanelScroll/LeftPanelColumn/WorldMapPanel
@onready var _survivor_panel: SurvivorPanel = $UIRoot/HUDLayer/GameHudLayout/LeftPanelScroll/LeftPanelColumn/SurvivorPanel
@onready var _offline_settlement_panel: OfflineSettlementPanel = $UIRoot/WindowLayer/OfflineSettlementPanel
@onready var _resource_ribbon: ResourceRibbon = $UIRoot/HUDLayer/GameHudLayout/ResourceRibbon
@onready var _ocean_map_hud: OceanMapHUD = $UIRoot/HUDLayer/GameHudLayout/OceanMapHUD

var _session: GameSession = null


func _ready() -> void:
	_hud_layout.map_navigation_changed.connect(_dynamic_ocean_map.set_navigation_mode)
	_hud_layout.build_mode_changed.connect(_set_build_mode)
	_dynamic_ocean_map.voyage_status_changed.connect(_ocean_map_hud.show_status)
	_dynamic_ocean_map.hovered_region_changed.connect(_ocean_map_hud.show_hovered_region)
	_dynamic_ocean_map.set_navigation_mode(true)
	_set_build_mode(false)
	get_viewport().size_changed.connect(_layout_world_views)
	_bind_views()
	call_deferred("_layout_world_views")


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
	_dynamic_ocean_map.bind_session(_session)
	_build_panel.bind_session(_session)
	_survival_hud.bind_session(_session)
	_production_panel.bind_session(_session)
	_world_map_panel.bind_session(_session)
	_survivor_panel.bind_session(_session)
	_offline_settlement_panel.show_report(_session.get_last_offline_settlement_report())
	_resource_ribbon.bind_session(_session)
	_ocean_map_hud.bind_session(_session)


func _set_build_mode(is_enabled: bool) -> void:
	_build_view.visible = is_enabled
	_dynamic_ocean_map.visible = not is_enabled


func _layout_world_views() -> void:
	_build_view.position = get_viewport().get_visible_rect().size * 0.5 + Vector2(0.0, 18.0)
