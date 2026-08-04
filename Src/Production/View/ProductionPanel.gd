class_name ProductionPanel
extends PanelContainer

## S3 facility and inventory UI. It submits commands and only reads session queries.

@onready var _inventory_label: Label = %InventoryLabel
@onready var _facility_label: Label = %FacilityLabel
@onready var _status_label: Label = %ProductionStatusLabel
@onready var _gather_wood_button: Button = %GatherWoodButton
@onready var _gather_fish_button: Button = %GatherFishButton
@onready var _gather_water_button: Button = %GatherWaterButton
@onready var _use_water_button: Button = %UseWaterButton
@onready var _use_fish_button: Button = %UseFishButton
@onready var _toggle_collector_button: Button = %ToggleCollectorButton
@onready var _toggle_campfire_button: Button = %ToggleCampfireButton
@onready var _toggle_repair_button: Button = %ToggleRepairButton

var _session: GameSession = null


func _ready() -> void:
	_gather_wood_button.pressed.connect(_gather.bind(&"item_wood"))
	_gather_fish_button.pressed.connect(_gather.bind(&"item_raw_fish"))
	_gather_water_button.pressed.connect(_gather.bind(&"item_seawater"))
	_use_water_button.pressed.connect(_use_food.bind(&"item_fresh_water"))
	_use_fish_button.pressed.connect(_use_food.bind(&"item_grilled_fish"))
	_toggle_collector_button.pressed.connect(_toggle_facility.bind(&"building_rain_collector"))
	_toggle_campfire_button.pressed.connect(_toggle_facility.bind(&"building_campfire"))
	_toggle_repair_button.pressed.connect(_toggle_facility.bind(&"building_repair_station"))
	_refresh()


func bind_session(session: GameSession) -> void:
	_session = session
	if _session != null:
		var inventory_system: InventorySystem = _session.get_inventory_system()
		if not inventory_system.item_amount_changed.is_connected(_on_item_amount_changed):
			inventory_system.item_amount_changed.connect(_on_item_amount_changed)
		var production_system: ProductionSystem = _session.get_production_system()
		if not production_system.production_changed.is_connected(_on_production_changed):
			production_system.production_changed.connect(_on_production_changed)
		if not _session.get_building_system().building_placed.is_connected(_on_building_placed):
			_session.get_building_system().building_placed.connect(_on_building_placed)
	_refresh()


func _gather(item_id: StringName) -> void:
	if _session == null:
		return
	_set_status(_session.execute_gather_resources(GatherResourcesCommand.new(item_id, 1)))


func _use_food(item_id: StringName) -> void:
	if _session == null:
		return
	_set_status(_session.execute_use_food(UseFoodCommand.new(item_id)))


func _toggle_facility(building_id: StringName) -> void:
	if _session == null or not _session.has_active_state():
		return
	for building: BuildingInstance in _session.get_raft_state().building_instances.values():
		if building.building_id != building_id:
			continue
		var production: ProductionInstance = _session.get_production_system().get_instance(_session.get_state(), building.instance_id)
		if production != null:
			_set_status(_session.execute_set_production_enabled(SetProductionEnabledCommand.new(building.instance_id, not production.is_enabled)))
			return
	_status_label.text = "先建造对应设施。"


func _on_item_amount_changed(_item_id: StringName, _amount: int) -> void:
	_refresh()


func _on_production_changed(_instance_id: StringName) -> void:
	_refresh()


func _on_building_placed(_instance_id: StringName, _building_id: StringName, _origin: Vector2i) -> void:
	_refresh()


func _set_status(result: CommandResult) -> void:
	_status_label.text = result.message
	_refresh()


func _refresh() -> void:
	if not is_instance_valid(_inventory_label):
		return
	if _session == null or not _session.has_active_state():
		_inventory_label.text = "库存：--"
		_facility_label.text = "设施：--"
		return
	_inventory_label.text = "木材 %d｜生鱼 %d｜海水 %d\n淡水 %d/%d｜烤鱼 %d/%d" % [
		_session.get_item_amount(&"item_wood"),
		_session.get_item_amount(&"item_raw_fish"),
		_session.get_item_amount(&"item_seawater"),
		_session.get_item_amount(&"item_fresh_water"),
		_session.get_inventory_system().get_capacity(_session.get_state(), &"item_fresh_water"),
		_session.get_item_amount(&"item_grilled_fish"),
		_session.get_inventory_system().get_capacity(_session.get_state(), &"item_grilled_fish"),
	]
	var facility_lines: PackedStringArray = []
	for building: BuildingInstance in _session.get_raft_state().building_instances.values():
		var production: ProductionInstance = _session.get_production_system().get_instance(_session.get_state(), building.instance_id)
		if production == null:
			continue
		var recipe: RecipeDefinition = _session.get_recipe_definition(production.recipe_id) if production.recipe_id != &"" else null
		var display_name: String = recipe.display_name if recipe != null else "维修"
		var reason: String = _get_stall_text(production.stall_reason)
		facility_lines.append("%s：%s（%.0fs，%s）" % [display_name, "运行" if production.is_enabled else "已停", production.progress_seconds, reason])
	_facility_label.text = "设施：\n%s" % "\n".join(facility_lines) if not facility_lines.is_empty() else "设施：建造集雨器、篝火或维修站后可运行。"


func _get_stall_text(reason: ProductionInstance.StallReason) -> String:
	match reason:
		ProductionInstance.StallReason.MANUALLY_STOPPED:
			return "已停"
		ProductionInstance.StallReason.SUPPLY_DEPLETED:
			return "补给耗尽"
		ProductionInstance.StallReason.MISSING_INPUT:
			return "缺原料"
		ProductionInstance.StallReason.OUTPUT_CAPACITY_REACHED:
			return "产物满仓"
	return "正常"
