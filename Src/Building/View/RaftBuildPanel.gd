class_name RaftBuildPanel
extends Control

## UI controller for the S1 build slice. It creates commands but never changes state directly.

@export var build_view_path: NodePath

@onready var _wood_label: Label = %WoodLabel
@onready var _status_label: Label = %BuildStatusLabel
@onready var _select_collector_button: Button = %SelectRainCollectorButton
@onready var _select_campfire_button: Button = %SelectCampfireButton
@onready var _select_repair_button: Button = %SelectRepairStationButton
@onready var _select_tank_button: Button = %SelectWaterTankButton
@onready var _select_rudder_button: Button = %SelectRudderButton
@onready var _confirm_button: Button = %ConfirmBuildButton
@onready var _cancel_button: Button = %CancelBuildButton

var _session: GameSession = null
var _build_view: RaftBuildView = null
var _inventory_system: InventorySystem = null
var _selected_building_id: StringName = &""
var _selected_cell: Vector2i = Vector2i.ZERO
var _has_selected_cell: bool = false


func _ready() -> void:
	_build_view = get_node_or_null(build_view_path) as RaftBuildView
	if _build_view != null:
		_build_view.tile_selected.connect(_on_tile_selected)
		_select_collector_button.pressed.connect(_select_building.bind(&"building_rain_collector"))
		_select_campfire_button.pressed.connect(_select_building.bind(&"building_campfire"))
		_select_repair_button.pressed.connect(_select_building.bind(&"building_repair_station"))
		_select_tank_button.pressed.connect(_select_building.bind(&"building_water_tank"))
		_select_rudder_button.pressed.connect(_select_building.bind(&"building_rudder"))
	_confirm_button.pressed.connect(_on_confirm_pressed)
	_cancel_button.pressed.connect(_on_cancel_pressed)
	_refresh()


func bind_session(session: GameSession) -> void:
	_session = session
	_inventory_system = _session.get_inventory_system() if _session != null else null
	if _inventory_system != null and not _inventory_system.item_amount_changed.is_connected(_on_item_amount_changed):
		_inventory_system.item_amount_changed.connect(_on_item_amount_changed)
	if _session != null and _session.get_building_system() != null:
		var building_system: BuildingSystem = _session.get_building_system()
		if not building_system.building_placed.is_connected(_on_building_placed):
			building_system.building_placed.connect(_on_building_placed)
	_refresh()


func _select_building(building_id: StringName) -> void:
	_selected_building_id = building_id
	_has_selected_cell = false
	_status_label.text = "选择竹筏格位放置设施。"
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
	var result: CommandResult = _session.execute_command(
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


func _on_item_amount_changed(_item_id: StringName, _new_amount: int) -> void:
	_refresh()


func _refresh() -> void:
	if not is_instance_valid(_wood_label):
		return
	var wood_amount: int = 0
	if _session != null:
		wood_amount = _session.get_item_amount(&"item_wood")
	_wood_label.text = "木材：%d" % wood_amount
	_refresh_select_button(_select_collector_button, &"building_rain_collector")
	_refresh_select_button(_select_campfire_button, &"building_campfire")
	_refresh_select_button(_select_repair_button, &"building_repair_station")
	_refresh_select_button(_select_tank_button, &"building_water_tank")
	_refresh_select_button(_select_rudder_button, &"building_rudder")
	_confirm_button.disabled = _selected_building_id == &"" or not _has_selected_cell
	_select_collector_button.disabled = _session == null
	_select_campfire_button.disabled = _session == null
	_select_repair_button.disabled = _session == null
	_select_tank_button.disabled = _session == null
	_select_rudder_button.disabled = _session == null


func _refresh_select_button(button: Button, building_id: StringName) -> void:
	if _session == null:
		button.text = "选择建筑"
		return
	var definition: BuildingDefinition = _session.get_building_definition(building_id)
	if definition == null:
		button.text = "设施不可用"
		return
	var cost_entries: PackedStringArray = []
	for item_id: StringName in definition.build_cost:
		cost_entries.append("%s×%d" % [String(item_id).trim_prefix("item_"), definition.build_cost[item_id]])
	button.text = "选择：%s（%s）" % [definition.display_name, "、".join(cost_entries)]
