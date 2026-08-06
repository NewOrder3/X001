class_name RaftBuildPanel
extends Control

## UI controller for the S1 build slice. It creates commands but never changes state directly.

@export var build_view_path: NodePath

@onready var _wood_label: Label = %WoodLabel
@onready var _raft_level_label: Label = %RaftLevelLabel
@onready var _raft_upgrade_button: Button = %RaftUpgradeButton
@onready var _status_label: Label = %BuildStatusLabel
@onready var _select_collector_button: Button = %SelectRainCollectorButton
@onready var _select_campfire_button: Button = %SelectCampfireButton
@onready var _select_repair_button: Button = %SelectRepairStationButton
@onready var _select_tank_button: Button = %SelectWaterTankButton
@onready var _select_rudder_button: Button = %SelectRudderButton
@onready var _select_desalinator_button: Button = %SelectDesalinatorButton
@onready var _select_fishing_net_button: Button = %SelectFishingNetButton
@onready var _select_storage_rack_button: Button = %SelectStorageRackButton
@onready var _confirm_button: Button = %ConfirmBuildButton
@onready var _cancel_button: Button = %CancelBuildButton
@onready var _facility_list: VBoxContainer = %FacilityList

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
		_select_desalinator_button.pressed.connect(_select_building.bind(&"building_desalinator"))
		_select_fishing_net_button.pressed.connect(_select_building.bind(&"building_fishing_net"))
		_select_storage_rack_button.pressed.connect(_select_building.bind(&"building_storage_rack"))
	_raft_upgrade_button.pressed.connect(_upgrade_raft)
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
		if not building_system.building_upgraded.is_connected(_on_building_upgraded):
			building_system.building_upgraded.connect(_on_building_upgraded)
		var progression_system: ProgressionSystem = _session.get_progression_system()
		if not progression_system.raft_upgraded.is_connected(_on_raft_upgraded):
			progression_system.raft_upgraded.connect(_on_raft_upgraded)
	_refresh()


func _select_building(building_id: StringName) -> void:
	_selected_building_id = building_id
	_has_selected_cell = false
	_status_label.text = GameText.get_text(&"ui.build.status_select_tile")
	if _build_view != null:
		_build_view.select_building(_selected_building_id)
	_refresh()


func _on_tile_selected(cell: Vector2i) -> void:
	_selected_cell = cell
	_has_selected_cell = true
	_status_label.text = GameText.format(&"ui.build.status_tile_selected", [cell.x, cell.y])
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
	_status_label.text = GameText.get_text(&"ui.build.status_cancelled")
	if _build_view != null:
		_build_view.select_building(&"")
	_refresh()


func _on_building_placed(_instance_id: StringName, _building_id: StringName, _origin: Vector2i) -> void:
	_refresh()
	if _build_view != null:
		_build_view.queue_redraw()


func _on_building_upgraded(_instance_id: StringName, _new_level: int) -> void:
	_refresh()
	if _build_view != null:
		_build_view.queue_redraw()


func _on_raft_upgraded(_new_level: int) -> void:
	_refresh()
	if _build_view != null:
		_build_view.queue_redraw()


func _upgrade_building(instance_id: StringName) -> void:
	if _session == null:
		return
	var result: CommandResult = _session.execute_command(UpgradeBuildingCommand.new(instance_id))
	_status_label.text = result.message
	_refresh()


func _upgrade_raft() -> void:
	if _session == null:
		return
	var result: CommandResult = _session.execute_command(UpgradeRaftCommand.new())
	_status_label.text = result.message
	_refresh()


func _on_item_amount_changed(_item_id: StringName, _new_amount: int) -> void:
	_refresh()


func _refresh() -> void:
	if not is_instance_valid(_wood_label):
		return
	var wood_amount: int = 0
	if _session != null:
		wood_amount = _session.get_item_amount(&"item_wood")
	_wood_label.text = GameText.format(&"ui.build.wood", [wood_amount])
	_refresh_raft_upgrade()
	_refresh_select_button(_select_collector_button, &"building_rain_collector")
	_refresh_select_button(_select_campfire_button, &"building_campfire")
	_refresh_select_button(_select_repair_button, &"building_repair_station")
	_refresh_select_button(_select_tank_button, &"building_water_tank")
	_refresh_select_button(_select_rudder_button, &"building_rudder")
	_refresh_select_button(_select_desalinator_button, &"building_desalinator")
	_refresh_select_button(_select_fishing_net_button, &"building_fishing_net")
	_refresh_select_button(_select_storage_rack_button, &"building_storage_rack")
	_confirm_button.disabled = _selected_building_id == &"" or not _has_selected_cell
	_select_collector_button.disabled = _session == null
	_select_campfire_button.disabled = _session == null
	_select_repair_button.disabled = _session == null
	_select_tank_button.disabled = _session == null
	_select_rudder_button.disabled = _session == null
	_select_desalinator_button.disabled = _session == null
	_select_fishing_net_button.disabled = _session == null
	_select_storage_rack_button.disabled = _session == null
	_refresh_facility_list()


func _refresh_raft_upgrade() -> void:
	if _session == null or not _session.has_active_state():
		_raft_level_label.text = GameText.get_text(&"ui.build.raft_no_session")
		_raft_upgrade_button.text = GameText.get_text(&"ui.build.upgrade_raft")
		_raft_upgrade_button.disabled = true
		return
	var raft_level: int = _session.get_raft_level()
	var deck_size: Vector2i = _session.get_raft_state().grid.get_deck_size()
	var upgrade_cost: Dictionary[StringName, int] = _session.get_raft_upgrade_cost()
	if upgrade_cost.is_empty():
		_raft_level_label.text = GameText.format(&"ui.build.raft_level_max", [raft_level, deck_size.x, deck_size.y])
		_raft_upgrade_button.text = GameText.get_text(&"ui.build.upgrade_raft_max")
		_raft_upgrade_button.disabled = true
		return
	_raft_level_label.text = GameText.format(&"ui.build.raft_level", [raft_level, deck_size.x, deck_size.y])
	_raft_upgrade_button.text = GameText.format(
		&"ui.build.upgrade_raft_cost",
		[_format_cost(upgrade_cost)],
	)
	_raft_upgrade_button.disabled = not _session.get_inventory_system().can_afford(
		_session.get_state().inventory_state,
		upgrade_cost,
	)


func _refresh_facility_list() -> void:
	for child: Node in _facility_list.get_children():
		child.queue_free()
	if _session == null or not _session.has_active_state():
		return
	for instance: BuildingInstance in _session.get_raft_state().building_instances.values():
		var definition: BuildingDefinition = _session.get_building_definition(instance.building_id)
		if definition == null:
			continue
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override(&"separation", 8)
		var name_label: Label = Label.new()
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.text = GameText.format(&"ui.build.facility_entry", [definition.get_display_name(), instance.level])
		row.add_child(name_label)
		var upgrade_button: Button = Button.new()
		if instance.level >= BuildingSystem.MAX_BUILDING_LEVEL:
			upgrade_button.text = GameText.get_text(&"ui.build.max_level")
			upgrade_button.disabled = true
		else:
			var cost: Dictionary[StringName, int] = _session.get_building_system().get_upgrade_cost(instance)
			upgrade_button.text = GameText.format(&"ui.build.upgrade_cost", [instance.level + 1, _format_cost(cost)])
			upgrade_button.disabled = not _session.get_inventory_system().can_afford(_session.get_state().inventory_state, cost)
			upgrade_button.pressed.connect(_upgrade_building.bind(instance.instance_id))
		row.add_child(upgrade_button)
		_facility_list.add_child(row)


func _format_cost(cost: Dictionary[StringName, int]) -> String:
	var entries: PackedStringArray = []
	for item_id: StringName in cost:
		var item: ItemDefinition = _session.get_item_definition(item_id)
		entries.append("%s×%d" % [item.get_display_name() if item != null else String(item_id), cost[item_id]])
	return "、".join(entries)


func _refresh_select_button(button: Button, building_id: StringName) -> void:
	if _session == null:
		button.text = GameText.get_text(&"ui.build.select_building")
		return
	var definition: BuildingDefinition = _session.get_building_definition(building_id)
	if definition == null:
		button.text = GameText.get_text(&"ui.build.unavailable")
		return
	var cost_entries: PackedStringArray = []
	for item_id: StringName in definition.build_cost:
		var item: ItemDefinition = _session.get_item_definition(item_id)
		var item_name: String = item.get_display_name() if item != null else String(item_id)
		cost_entries.append(GameText.format(&"ui.build.cost_entry", [item_name, definition.build_cost[item_id]]))
	button.text = GameText.format(&"ui.build.select_with_cost", [definition.get_display_name(), "、".join(cost_entries)])
