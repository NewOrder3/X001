class_name GameRoot
extends Node

@onready var _build_view: RaftBuildView = $RaftBuildView
@onready var _dynamic_ocean_map: DynamicOceanMap = $DynamicOceanMap
@onready var _hud_layout: GameHudLayout = $UIRoot/HUDLayer/GameHudLayout
@onready var _build_panel: RaftBuildPanel = $UIRoot/HUDLayer/GameHudLayout/LeftPanelScroll/LeftPanelColumn/RaftBuildPanel
@onready var _survival_hud: SurvivalHUD = $UIRoot/HUDLayer/GameHudLayout/SurvivalHUD
@onready var _production_panel: ProductionPanel = $UIRoot/HUDLayer/GameHudLayout/LeftPanelScroll/LeftPanelColumn/ProductionPanel
@onready var _world_map_panel: WorldMapPanel = $UIRoot/HUDLayer/GameHudLayout/LeftPanelScroll/LeftPanelColumn/WorldMapPanel
@onready var _exploration_result_card: ExplorationResultCard = $UIRoot/WindowLayer/ExplorationResultCard
@onready var _battle_preparation_card: BattlePreparationCard = $UIRoot/WindowLayer/BattlePreparationCard
@onready var _survivor_panel: SurvivorPanel = $UIRoot/HUDLayer/GameHudLayout/LeftPanelScroll/LeftPanelColumn/SurvivorPanel
@onready var _merchant_panel: MerchantPanel = $UIRoot/HUDLayer/GameHudLayout/LeftPanelScroll/LeftPanelColumn/MerchantPanel
@onready var _goal_panel: GoalPanel = $UIRoot/HUDLayer/GameHudLayout/LeftPanelScroll/LeftPanelColumn/GoalPanel
@onready var _current_goal_hud: CurrentGoalHud = $UIRoot/HUDLayer/GameHudLayout/CurrentGoalHud
@onready var _quest_feedback_banner: QuestFeedbackBanner = $UIRoot/HUDLayer/GameHudLayout/QuestFeedbackBanner
@onready var _menu_panel: GameMenuPanel = $UIRoot/WindowLayer/GameMenuPanel
@onready var _ui_root: UIRoot = $UIRoot
@onready var _offline_settlement_panel: OfflineSettlementPanel = $UIRoot/WindowLayer/OfflineSettlementPanel
@onready var _resource_ribbon: ResourceRibbon = $UIRoot/HUDLayer/GameHudLayout/ResourceRibbon
@onready var _ocean_map_hud: OceanMapHUD = $UIRoot/HUDLayer/GameHudLayout/OceanMapHUD

var _session: GameSession = null


func _ready() -> void:
	_hud_layout.map_navigation_changed.connect(_dynamic_ocean_map.set_navigation_mode)
	_hud_layout.raft_view_changed.connect(_set_raft_view)
	_dynamic_ocean_map.voyage_status_changed.connect(_ocean_map_hud.show_status)
	_dynamic_ocean_map.hovered_region_changed.connect(_ocean_map_hud.show_hovered_region)
	_dynamic_ocean_map.set_navigation_mode(true)
	_set_raft_view(false, false, false)
	_build_view.salvage_requested.connect(_on_salvage_requested)
	_goal_panel.navigate_requested.connect(_hud_layout.open_panel)
	_goal_panel.battle_requested.connect(_start_goal_battle)
	_survival_hud.navigate_requested.connect(_hud_layout.open_panel)
	_survival_hud.display_mode_changed.connect(_hud_layout.refresh_layout)
	_current_goal_hud.navigate_requested.connect(_hud_layout.open_panel)
	_current_goal_hud.battle_requested.connect(_start_goal_battle)
	_production_panel.navigate_requested.connect(_hud_layout.open_panel)
	_world_map_panel.navigate_requested.connect(_hud_layout.open_panel)
	_world_map_panel.boss_challenge_requested.connect(_start_goal_battle)
	_exploration_result_card.result_ready.connect(_show_exploration_result)
	_exploration_result_card.navigate_requested.connect(_open_exploration_result_action)
	_exploration_result_card.close_requested.connect(_close_exploration_result)
	_battle_preparation_card.start_requested.connect(_begin_battle)
	_battle_preparation_card.navigate_requested.connect(_open_battle_preparation_action)
	_battle_preparation_card.close_requested.connect(_close_battle_preparation)
	_ui_root.register_window(&"game_menu", _menu_panel)
	_ui_root.register_window(&"exploration_result", _exploration_result_card)
	_ui_root.register_window(&"battle_preparation", _battle_preparation_card)
	_hud_layout.menu_requested.connect(_open_menu)
	_menu_panel.close_requested.connect(_close_menu)
	_menu_panel.return_to_main_menu_requested.connect(_return_to_main_menu)
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
	_exploration_result_card.bind_session(_session)
	_battle_preparation_card.bind_session(_session)
	_survivor_panel.bind_session(_session)
	_merchant_panel.bind_session(_session)
	_goal_panel.bind_session(_session)
	_current_goal_hud.bind_session(_session)
	_quest_feedback_banner.bind_session(_session)
	_menu_panel.bind_session(_session)
	_offline_settlement_panel.show_report(_session.get_last_offline_settlement_report())
	_resource_ribbon.bind_session(_session)
	_ocean_map_hud.bind_session(_session)


func _start_goal_battle(boss_id: StringName) -> void:
	if _session == null:
		return
	_battle_preparation_card.show_boss(boss_id)
	_ui_root.open_window(&"battle_preparation")


func _begin_battle(boss_id: StringName) -> void:
	if _session == null:
		return
	_close_battle_preparation()
	var result: CommandResult = _session.execute_command(StartBattleCommand.new(boss_id))
	if not result.succeeded:
		_ui_root.show_popup(result.message)


func _show_exploration_result() -> void:
	_ui_root.open_window(&"exploration_result")


func _open_exploration_result_action(panel_id: StringName) -> void:
	_close_exploration_result()
	_hud_layout.open_panel(panel_id)


func _close_exploration_result() -> void:
	_ui_root.close_topmost()


func _open_battle_preparation_action(panel_id: StringName) -> void:
	_close_battle_preparation()
	_hud_layout.open_panel(panel_id)


func _close_battle_preparation() -> void:
	_ui_root.close_topmost()


func _open_menu() -> void:
	if _session != null:
		_session.get_simulation_clock().pause()
	_menu_panel.refresh()
	_ui_root.open_window(&"game_menu")


func _close_menu() -> void:
	_ui_root.close_topmost()
	if _session != null:
		_session.get_simulation_clock().start()


func _return_to_main_menu() -> void:
	_ui_root.close_topmost()
	var router: SceneRouter = get_node_or_null("../../SceneRouter") as SceneRouter
	if router != null:
		router.go_to_main_menu()


func _set_raft_view(is_visible: bool, is_interactive: bool, is_salvage_available: bool) -> void:
	_build_view.visible = is_visible
	_build_view.set_interaction_enabled(is_interactive)
	_build_view.set_salvage_spots_visible(is_visible and is_salvage_available)
	_dynamic_ocean_map.visible = not is_visible


func _on_salvage_requested(item_id: StringName) -> void:
	if _session == null:
		return
	var result: CommandResult = _session.execute_command(GatherResourcesCommand.new(item_id, 1))
	if not result.succeeded:
		_ui_root.show_popup(result.message)


func _layout_world_views() -> void:
	_build_view.position = get_viewport().get_visible_rect().size * 0.5 + Vector2(0.0, 18.0)
