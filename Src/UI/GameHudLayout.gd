class_name GameHudLayout
extends Control

## Home-screen composition: information stays at the top while detailed systems live
## in a single bottom drawer selected by the navigation bar.

const COMPACT_WIDTH: float = 900.0
const DRAWER_MARGIN: float = 32.0

signal map_navigation_changed(is_enabled: bool)
signal build_mode_changed(is_enabled: bool)
signal menu_requested

@onready var _left_panel_scroll: ScrollContainer = $LeftPanelScroll
@onready var _survival_hud: Control = $SurvivalHUD
@onready var _resource_ribbon: Control = $ResourceRibbon
@onready var _current_goal_hud: Control = $CurrentGoalHud
@onready var _quest_feedback_banner: Control = $QuestFeedbackBanner
@onready var _bottom_navigation: PanelContainer = $BottomNavigation
@onready var _build_panel: Control = $LeftPanelScroll/LeftPanelColumn/RaftBuildPanel
@onready var _production_panel: Control = $LeftPanelScroll/LeftPanelColumn/ProductionPanel
@onready var _world_map_panel: Control = $LeftPanelScroll/LeftPanelColumn/WorldMapPanel
@onready var _survivor_panel: Control = $LeftPanelScroll/LeftPanelColumn/SurvivorPanel
@onready var _merchant_panel: Control = $LeftPanelScroll/LeftPanelColumn/MerchantPanel
@onready var _goal_panel: Control = $LeftPanelScroll/LeftPanelColumn/GoalPanel
@onready var _menu_button: Button = $MenuButton
@onready var _voyage_header: Control = $OceanMapHUD/VoyageHeader
@onready var _voyage_status: Control = $OceanMapHUD/VoyageStatus

var _active_panel: Control = null


func _ready() -> void:
	get_viewport().size_changed.connect(_apply_layout)
	$BottomNavigation/Buttons/MapButton.pressed.connect(_show_ocean_map)
	$BottomNavigation/Buttons/BuildButton.pressed.connect(_toggle_panel.bind(_build_panel))
	$BottomNavigation/Buttons/SupplyButton.pressed.connect(_toggle_panel.bind(_production_panel))
	$BottomNavigation/Buttons/CrewButton.pressed.connect(_toggle_panel.bind(_survivor_panel))
	$BottomNavigation/Buttons/GoalButton.pressed.connect(_toggle_panel.bind(_goal_panel))
	$BottomNavigation/Buttons/MerchantButton.pressed.connect(_toggle_panel.bind(_merchant_panel))
	_menu_button.pressed.connect(menu_requested.emit)
	_apply_styles()
	_apply_nav_tooltips()
	_set_active_panel(null)
	call_deferred("_apply_layout")


func open_map_drawer() -> void:
	_set_active_panel(_world_map_panel)


func is_map_drawer_open() -> bool:
	return _active_panel == _world_map_panel


func _toggle_panel(panel: Control) -> void:
	_set_active_panel(null if _active_panel == panel else panel)


func _show_ocean_map() -> void:
	_set_active_panel(null)


func _set_active_panel(panel: Control) -> void:
	_active_panel = panel
	for candidate: Control in [_goal_panel, _build_panel, _production_panel, _world_map_panel, _survivor_panel, _merchant_panel]:
		candidate.visible = candidate == _active_panel
	if _active_panel != null and _active_panel.has_method("refresh"):
		_active_panel.call("refresh")
	_left_panel_scroll.visible = _active_panel != null
	var is_build_mode: bool = _active_panel == _build_panel
	map_navigation_changed.emit(_active_panel == null or _active_panel == _world_map_panel)
	build_mode_changed.emit(is_build_mode)
	_voyage_header.visible = not is_build_mode
	_voyage_status.visible = not is_build_mode
	_apply_layout()


func _apply_layout() -> void:
	if not is_instance_valid(_left_panel_scroll):
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x < COMPACT_WIDTH:
		_apply_compact_layout(viewport_size)
		return
	_apply_wide_layout(viewport_size)


func _apply_wide_layout(viewport_size: Vector2) -> void:
	_voyage_header.visible = _active_panel != _build_panel
	_resource_ribbon.position = Vector2(DRAWER_MARGIN, DRAWER_MARGIN)
	_resource_ribbon.size = Vector2(330.0, 92.0)
	_current_goal_hud.position = Vector2((viewport_size.x - 480.0) * 0.5, 24.0)
	_current_goal_hud.size = Vector2(480.0, 132.0)
	_quest_feedback_banner.position = Vector2((viewport_size.x - 480.0) * 0.5, 174.0)
	_quest_feedback_banner.size = Vector2(480.0, 76.0)
	_survival_hud.position = Vector2(viewport_size.x - 300.0 - DRAWER_MARGIN, DRAWER_MARGIN + 52.0)
	_survival_hud.size = Vector2(300.0, 154.0)
	_menu_button.position = Vector2(viewport_size.x - 132.0 - DRAWER_MARGIN, DRAWER_MARGIN)
	_menu_button.size = Vector2(132.0, 44.0)
	_bottom_navigation.size = Vector2(minf(900.0, viewport_size.x - 280.0), 112.0)
	_bottom_navigation.position = Vector2((viewport_size.x - _bottom_navigation.size.x) * 0.5, viewport_size.y - 136.0)
	_voyage_header.size = Vector2(520.0, 88.0)
	_voyage_header.position = Vector2((viewport_size.x - _voyage_header.size.x) * 0.5, 258.0)
	_voyage_status.size = Vector2(minf(680.0, viewport_size.x - 420.0), 58.0)
	_voyage_status.position = Vector2((viewport_size.x - _voyage_status.size.x) * 0.5, viewport_size.y - 214.0)
	if _active_panel != null:
		_left_panel_scroll.position = Vector2(DRAWER_MARGIN, 154.0)
		_left_panel_scroll.size = Vector2(468.0, maxf(240.0, viewport_size.y - 320.0))
		_left_panel_scroll.position.y = 206.0
		_left_panel_scroll.size.y = maxf(200.0, viewport_size.y - 372.0)


func _apply_compact_layout(viewport_size: Vector2) -> void:
	_voyage_header.hide()
	_resource_ribbon.position = Vector2(16.0, 16.0)
	_resource_ribbon.size = Vector2(viewport_size.x * 0.48 - 20.0, 76.0)
	_survival_hud.position = Vector2(viewport_size.x * 0.48 + 4.0, 16.0)
	_survival_hud.size = Vector2(viewport_size.x * 0.52 - 20.0, 116.0)
	_current_goal_hud.position = Vector2(16.0, 142.0)
	_current_goal_hud.size = Vector2(viewport_size.x - 32.0, 112.0)
	_quest_feedback_banner.position = Vector2(16.0, 262.0)
	_quest_feedback_banner.size = Vector2(viewport_size.x - 32.0, 68.0)
	_menu_button.position = Vector2(16.0, 16.0)
	_menu_button.size = Vector2(96.0, 44.0)
	_bottom_navigation.position = Vector2(16.0, viewport_size.y - 102.0)
	_bottom_navigation.size = Vector2(viewport_size.x - 32.0, 86.0)
	_voyage_header.position = Vector2(viewport_size.x * 0.18, 340.0)
	_voyage_header.size = Vector2(viewport_size.x * 0.64, 76.0)
	_voyage_status.position = Vector2(20.0, viewport_size.y - 154.0)
	_voyage_status.size = Vector2(viewport_size.x - 40.0, 44.0)
	if _active_panel != null:
		_left_panel_scroll.position = Vector2(16.0, 344.0)
		_left_panel_scroll.size = Vector2(viewport_size.x - 32.0, maxf(160.0, viewport_size.y - 262.0))
		_left_panel_scroll.size.y = maxf(140.0, viewport_size.y - 462.0)


func _apply_styles() -> void:
	for panel: Control in [_goal_panel, _build_panel, _production_panel, _world_map_panel, _survivor_panel, _merchant_panel, _survival_hud, _current_goal_hud, _quest_feedback_banner]:
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color(0.045, 0.12, 0.15, 0.90)
		style.corner_radius_top_left = 18
		style.corner_radius_top_right = 18
		style.corner_radius_bottom_right = 18
		style.corner_radius_bottom_left = 18
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.83, 0.65, 0.35, 0.70)
		panel.add_theme_stylebox_override(&"panel", style)
	var nav_style: StyleBoxFlat = StyleBoxFlat.new()
	nav_style.bg_color = Color(0.10, 0.12, 0.12, 0.92)
	nav_style.corner_radius_top_left = 22
	nav_style.corner_radius_top_right = 22
	nav_style.corner_radius_bottom_right = 22
	nav_style.corner_radius_bottom_left = 22
	nav_style.border_width_top = 2
	nav_style.border_width_bottom = 2
	nav_style.border_width_left = 2
	nav_style.border_width_right = 2
	nav_style.border_color = Color(0.73, 0.45, 0.22, 0.85)
	_bottom_navigation.add_theme_stylebox_override(&"panel", nav_style)
	for button: Button in [$BottomNavigation/Buttons/MapButton, $BottomNavigation/Buttons/GoalButton, $BottomNavigation/Buttons/BuildButton, $BottomNavigation/Buttons/SupplyButton, $BottomNavigation/Buttons/CrewButton, $BottomNavigation/Buttons/MerchantButton]:
		var normal: StyleBoxFlat = StyleBoxFlat.new()
		normal.bg_color = Color("b9783c")
		normal.corner_radius_top_left = 14
		normal.corner_radius_top_right = 14
		normal.corner_radius_bottom_right = 14
		normal.corner_radius_bottom_left = 14
		button.add_theme_stylebox_override(&"normal", normal)
		var hover: StyleBoxFlat = normal.duplicate()
		hover.bg_color = Color("dd9c53")
		button.add_theme_stylebox_override(&"hover", hover)
		button.add_theme_color_override(&"font_color", Color("302017"))
		button.add_theme_font_size_override(&"font_size", 20)


func open_panel(panel_id: StringName) -> void:
	match panel_id:
		&"build":
			_set_active_panel(_build_panel)
		&"supply":
			_set_active_panel(_production_panel)
		&"map":
			_set_active_panel(_world_map_panel)
		&"crew":
			_set_active_panel(_survivor_panel)
		&"merchant":
			_set_active_panel(_merchant_panel)
		&"goal":
			_set_active_panel(_goal_panel)
		_:
			_set_active_panel(null)


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	match key_event.keycode:
		KEY_1:
			_set_active_panel(null)
			get_viewport().set_input_as_handled()
		KEY_2:
			_set_active_panel(_goal_panel)
			get_viewport().set_input_as_handled()
		KEY_3:
			_set_active_panel(_build_panel)
			get_viewport().set_input_as_handled()
		KEY_4:
			_set_active_panel(_production_panel)
			get_viewport().set_input_as_handled()
		KEY_5:
			_set_active_panel(_survivor_panel)
			get_viewport().set_input_as_handled()
		KEY_6:
			_set_active_panel(_merchant_panel)
			get_viewport().set_input_as_handled()
		KEY_ESCAPE:
			if _active_panel != null:
				_set_active_panel(null)
				get_viewport().set_input_as_handled()


func _apply_nav_tooltips() -> void:
	$BottomNavigation/Buttons/MapButton.tooltip_text = GameText.get_text(&"ui.nav.tip_map")
	$BottomNavigation/Buttons/GoalButton.tooltip_text = GameText.get_text(&"ui.nav.tip_goal")
	$BottomNavigation/Buttons/BuildButton.tooltip_text = GameText.get_text(&"ui.nav.tip_build")
	$BottomNavigation/Buttons/SupplyButton.tooltip_text = GameText.get_text(&"ui.nav.tip_supply")
	$BottomNavigation/Buttons/CrewButton.tooltip_text = GameText.get_text(&"ui.nav.tip_crew")
	$BottomNavigation/Buttons/MerchantButton.tooltip_text = GameText.get_text(&"ui.nav.tip_merchant")
	_menu_button.tooltip_text = GameText.get_text(&"ui.nav.tip_menu")
