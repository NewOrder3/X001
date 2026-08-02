class_name RaftBuildPanel
extends Control

## UI controller for the S1 build slice. It creates commands but never changes state directly.

@export var build_view_path: NodePath

@onready var _wood_label: Label = %WoodLabel
@onready var _status_label: Label = %BuildStatusLabel
@onready var _select_button: Button = %SelectRainCollectorButton
@onready var _confirm_button: Button = %ConfirmBuildButton
@onready var _cancel_button: Button = %CancelBuildButton

var _session: GameSession = null
var _build_view: RaftBuildView = null
var _selected_building_id: StringName = &""
var _selected_cell: Vector2i = Vector2i.ZERO
var _has_selected_cell: bool = false


func _ready() -> void:
	_build_view = get_node_or_null(build_view_path) as RaftBuildView
	if _build_view != null:
		_build_view.tile_selected.connect(_on_tile_selected)
	_select_button.pressed.connect(_on_select_rain_collector_pressed)
	_confirm_button.pressed.connect(_on_confirm_pressed)
	_cancel_button.pressed.connect(_on_cancel_pressed)
	_refresh()


func bind_session(session: GameSession) -> void:
	_session = session
	if _session != null and _session.get_building_system() != null:
		var building_system: BuildingSystem = _session.get_building_system()
		if not building_system.building_placed.is_connected(_on_building_placed):
			building_system.building_placed.connect(_on_building_placed)
	_refresh()


func _on_select_rain_collector_pressed() -> void:
	_selected_building_id = &"building_rain_collector"
	_has_selected_cell = false
	_status_label.text = "选择竹筏格位放置雨水收集器。"
	if _build_view != null:
		_build_view.select_building(_selected_building_id)
	_refresh()


func _on_tile_selected(cell: Vector2i) -> void:
	_selected_cell = cell
	_has_selected_cell = true
	_status_label.text = "已选择格位 (%d, %d)，确认后建造。" % [cell.x, cell.y]
	_refresh()


func _on_confirm_pressed() -> void:
	if _session == null or _selected_building_id == &"" or not _has_selected_cell:
		return
	var result: CommandResult = _session.execute_place_building(
		PlaceBuildingCommand.new(_selected_building_id, _selected_cell, 0)
	)
	_status_label.text = result.message
	if result.succeeded:
		_has_selected_cell = false
		if _build_view != null:
			_build_view.clear_preview()
	_refresh()


func _on_cancel_pressed() -> void:
	_selected_building_id = &""
	_has_selected_cell = false
	_status_label.text = "已取消建造。"
	if _build_view != null:
		_build_view.select_building(&"")
	_refresh()


func _on_building_placed(_instance_id: StringName, _building_id: StringName, _origin: Vector2i) -> void:
	_refresh()
	if _build_view != null:
		_build_view.queue_redraw()


func _refresh() -> void:
	if not is_instance_valid(_wood_label):
		return
	var wood_amount: int = 0
	if _session != null:
		wood_amount = _session.get_item_amount(&"item_wood")
	_wood_label.text = "木材：%d" % wood_amount
	_confirm_button.disabled = _selected_building_id == &"" or not _has_selected_cell
	_select_button.disabled = _session == null
