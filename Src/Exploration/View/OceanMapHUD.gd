class_name OceanMapHUD
extends Control

## Read-only voyage guidance for the direct-manipulation ocean map.

@onready var _header_panel: PanelContainer = $VoyageHeader
@onready var _region_label: Label = %VoyageRegionLabel
@onready var _hint_label: Label = %VoyageHintLabel
@onready var _status_panel: PanelContainer = $VoyageStatus
@onready var _status_label: Label = %VoyageStatusLabel

var _session: GameSession = null
var _last_status: String = ""
var _hovered_region_name: String = ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_styles()
	_refresh()


func bind_session(session: GameSession) -> void:
	_session = session
	if _session != null:
		var exploration_system: ExplorationSystem = _session.get_exploration_system()
		if not exploration_system.exploration_completed.is_connected(_on_exploration_completed):
			exploration_system.exploration_completed.connect(_on_exploration_completed)
		var building_system: BuildingSystem = _session.get_building_system()
		if not building_system.building_placed.is_connected(_on_building_changed):
			building_system.building_placed.connect(_on_building_changed)
		if not building_system.building_upgraded.is_connected(_on_building_upgraded):
			building_system.building_upgraded.connect(_on_building_upgraded)
	_refresh()


func show_status(message: String) -> void:
	_last_status = message
	_refresh()


func show_hovered_region(region_name: String) -> void:
	_hovered_region_name = region_name
	_refresh()


func _on_exploration_completed(result: ExplorationResult) -> void:
	_last_status = result.message
	_refresh()


func _on_building_changed(_instance_id: StringName, _building_id: StringName, _origin: Vector2i) -> void:
	_refresh()


func _on_building_upgraded(_instance_id: StringName, _new_level: int) -> void:
	_refresh()


func _refresh() -> void:
	if not is_instance_valid(_region_label):
		return
	if _session == null or not _session.has_active_state():
		_region_label.text = GameText.get_text(&"ui.ocean_map.waiting")
		_hint_label.text = ""
		_status_label.text = ""
		return
	var world_state: WorldState = _session.get_world_state()
	var region: RegionDefinition = _session.get_region_definition(world_state.current_region_id)
	if region != null:
		_region_label.text = GameText.format(&"ui.ocean_map.region", [region.get_display_name(), region.coordinate.x, region.coordinate.y])
	if not _hovered_region_name.is_empty():
		_hint_label.text = GameText.format(&"ui.ocean_map.hover_hint", [_hovered_region_name])
	elif _session.is_exploration_unlocked():
		_hint_label.text = GameText.get_text(&"ui.ocean_map.sail_hint")
	else:
		_hint_label.text = GameText.get_text(&"ui.ocean_map.build_rudder_hint")
	_status_label.text = _last_status if not _last_status.is_empty() else GameText.get_text(&"ui.ocean_map.default_status")


func _apply_styles() -> void:
	var header_style: StyleBoxFlat = StyleBoxFlat.new()
	header_style.bg_color = Color(0.025, 0.10, 0.14, 0.86)
	header_style.corner_radius_top_left = 18
	header_style.corner_radius_top_right = 18
	header_style.corner_radius_bottom_left = 18
	header_style.corner_radius_bottom_right = 18
	header_style.border_width_left = 1
	header_style.border_width_top = 1
	header_style.border_width_right = 1
	header_style.border_width_bottom = 1
	header_style.border_color = Color(0.67, 0.88, 0.84, 0.48)
	_header_panel.add_theme_stylebox_override(&"panel", header_style)
	var status_style: StyleBoxFlat = header_style.duplicate()
	status_style.bg_color = Color(0.07, 0.16, 0.18, 0.90)
	status_style.border_color = Color(0.95, 0.71, 0.30, 0.70)
	_status_panel.add_theme_stylebox_override(&"panel", status_style)
