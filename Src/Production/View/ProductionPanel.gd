class_name ProductionPanel
extends PanelContainer

## S3 facility and inventory UI. It submits commands and only reads session queries.

signal navigate_requested(panel_id: StringName)

@onready var _inventory_label: Label = %InventoryLabel
@onready var _facility_cards: VBoxContainer = %ProductionFacilityCards
@onready var _status_label: Label = %ProductionStatusLabel
@onready var _use_water_button: Button = %UseWaterButton
@onready var _use_fish_button: Button = %UseFishButton

var _session: GameSession = null


func _ready() -> void:
	_use_water_button.pressed.connect(_use_food.bind(&"item_fresh_water"))
	_use_fish_button.pressed.connect(_use_food.bind(&"item_grilled_fish"))
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


func _use_food(item_id: StringName) -> void:
	if _session == null:
		return
	_set_status(_session.execute_command(UseFoodCommand.new(item_id)))


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
		_inventory_label.text = GameText.get_text(&"ui.production.inventory_empty")
		_refresh_facility_cards()
		return
	_inventory_label.text = GameText.format(&"ui.production.inventory", [
		_get_item_name(&"item_wood"), _session.get_item_amount(&"item_wood"),
		_get_item_name(&"item_raw_fish"), _session.get_item_amount(&"item_raw_fish"),
		_get_item_name(&"item_seawater"), _session.get_item_amount(&"item_seawater"),
		_get_item_name(&"item_fresh_water"), _session.get_item_amount(&"item_fresh_water"),
		_session.get_inventory_system().get_capacity(_session.get_state(), &"item_fresh_water"),
		_get_item_name(&"item_grilled_fish"), _session.get_item_amount(&"item_grilled_fish"),
		_session.get_inventory_system().get_capacity(_session.get_state(), &"item_grilled_fish"),
	])
	_refresh_facility_cards()


func _refresh_facility_cards() -> void:
	for child: Node in _facility_cards.get_children():
		child.queue_free()
	if _session == null or not _session.has_active_state():
		_add_empty_facility_hint()
		return
	var has_facility: bool = false
	for building: BuildingInstance in _session.get_raft_state().building_instances.values():
		var production: ProductionInstance = _session.get_production_system().get_instance(_session.get_state(), building.instance_id)
		if production == null:
			continue
		has_facility = true
		_add_facility_card(building, production)
	if not has_facility:
		_add_empty_facility_hint()


func _add_empty_facility_hint() -> void:
	var hint: Label = Label.new()
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.text = GameText.get_text(&"ui.production.facility_none")
	_facility_cards.add_child(hint)


func _add_facility_card(building: BuildingInstance, production: ProductionInstance) -> void:
	var card: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.18, 0.20, 0.88)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.40, 0.72, 0.70, 0.55)
	card.add_theme_stylebox_override(&"panel", style)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override(&"margin_left", 12)
	margin.add_theme_constant_override(&"margin_top", 10)
	margin.add_theme_constant_override(&"margin_right", 12)
	margin.add_theme_constant_override(&"margin_bottom", 10)
	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override(&"separation", 4)
	var definition: BuildingDefinition = _session.get_building_definition(building.building_id)
	var title: Label = Label.new()
	title.add_theme_font_size_override(&"font_size", 18)
	title.text = definition.get_display_name() if definition != null else String(building.building_id)
	var recipe: RecipeDefinition = _session.get_recipe_definition(production.recipe_id) if production.recipe_id != &"" else null
	var detail: Label = Label.new()
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.text = _get_facility_detail(recipe, production)
	var action: Button = Button.new()
	action.custom_minimum_size = Vector2(0.0, 38.0)
	action.text = _get_facility_action_text(production)
	action.disabled = production.stall_reason == ProductionInstance.StallReason.SUPPLY_DEPLETED and _get_available_supply_item() == &""
	action.pressed.connect(_perform_facility_action.bind(building.instance_id))
	content.add_child(title)
	content.add_child(detail)
	content.add_child(action)
	margin.add_child(content)
	card.add_child(margin)
	_facility_cards.add_child(card)


func _get_facility_detail(recipe: RecipeDefinition, production: ProductionInstance) -> String:
	var state_key: StringName = &"ui.production.running" if production.stall_reason == ProductionInstance.StallReason.NONE else &"ui.production.stopped"
	var progress: String = GameText.format(&"ui.production.card_progress", [production.progress_seconds, recipe.cycle_seconds]) if recipe != null else GameText.get_text(&"ui.production.card_repair_progress")
	var recipe_text: String = GameText.format(&"ui.production.card_recipe", [_format_items(recipe.input_items), _format_items(recipe.output_items)]) if recipe != null else GameText.get_text(&"ui.production.card_repair")
	return GameText.format(&"ui.production.card_detail", [GameText.get_text(state_key), _get_localized_stall_text(production.stall_reason), progress, recipe_text])


func _get_facility_action_text(production: ProductionInstance) -> String:
	match production.stall_reason:
		ProductionInstance.StallReason.MANUALLY_STOPPED:
			return GameText.get_text(&"ui.production.resolve_restart")
		ProductionInstance.StallReason.MISSING_INPUT:
			var recipe: RecipeDefinition = _session.get_recipe_definition(production.recipe_id)
			if recipe != null:
				for item_id: StringName in recipe.input_items:
					return GameText.format(&"ui.production.resolve_salvage", [_get_item_name(item_id)])
		ProductionInstance.StallReason.SUPPLY_DEPLETED:
			return GameText.get_text(&"ui.production.resolve_supply" if _get_available_supply_item() != &"" else &"ui.production.resolve_no_supply")
		ProductionInstance.StallReason.OUTPUT_CAPACITY_REACHED:
			return GameText.get_text(&"ui.production.resolve_storage")
	return GameText.get_text(&"ui.production.pause" if production.is_enabled else &"ui.production.resolve_restart")


func _perform_facility_action(instance_id: StringName) -> void:
	if _session == null:
		return
	var production: ProductionInstance = _session.get_production_system().get_instance(_session.get_state(), instance_id)
	if production == null:
		return
	match production.stall_reason:
		ProductionInstance.StallReason.MISSING_INPUT:
			var recipe: RecipeDefinition = _session.get_recipe_definition(production.recipe_id)
			if recipe != null:
				for item_id: StringName in recipe.input_items:
					_status_label.text = GameText.format(&"ui.production.salvage_needed", [_get_item_name(item_id)])
					return
		ProductionInstance.StallReason.SUPPLY_DEPLETED:
			var supply_item_id: StringName = _get_available_supply_item()
			if supply_item_id != &"":
				_use_food(supply_item_id)
		ProductionInstance.StallReason.OUTPUT_CAPACITY_REACHED:
			navigate_requested.emit(&"build")
		_:
			_set_status(_session.execute_command(SetProductionEnabledCommand.new(instance_id, not production.is_enabled)))


func _format_items(items: Dictionary[StringName, int]) -> String:
	if items.is_empty():
		return GameText.get_text(&"ui.production.no_input")
	var entries: PackedStringArray = []
	for item_id: StringName in items:
		entries.append(GameText.format(&"ui.production.item_amount", [_get_item_name(item_id), items[item_id]]))
	return "、".join(entries)


func _get_available_supply_item() -> StringName:
	for item_id: StringName in [&"item_fresh_water", &"item_grilled_fish"]:
		if _session.get_item_amount(item_id) > 0:
			return item_id
	return &""


func _get_item_name(item_id: StringName) -> String:
	var definition: ItemDefinition = _session.get_item_definition(item_id)
	return definition.get_display_name() if definition != null else String(item_id)


func _get_localized_stall_text(reason: ProductionInstance.StallReason) -> String:
	match reason:
		ProductionInstance.StallReason.MANUALLY_STOPPED:
			return GameText.get_text(&"ui.production.stall_manually_stopped")
		ProductionInstance.StallReason.SUPPLY_DEPLETED:
			return GameText.get_text(&"ui.production.stall_supply_depleted")
		ProductionInstance.StallReason.MISSING_INPUT:
			return GameText.get_text(&"ui.production.stall_missing_input")
		ProductionInstance.StallReason.OUTPUT_CAPACITY_REACHED:
			return GameText.get_text(&"ui.production.stall_output_full")
	return GameText.get_text(&"ui.production.stall_normal")
