class_name WorldMapPanel
extends PanelContainer

## S4 map input surface. It submits a command and renders only public session queries/results.

@onready var _current_region_label: Label = %CurrentRegionLabel
@onready var _region_buttons: VBoxContainer = %RegionButtons
@onready var _preview_label: Label = %ExplorationPreviewLabel
@onready var _confirm_button: Button = %ConfirmExploreButton
@onready var _cancel_button: Button = %CancelExploreButton
@onready var _status_label: Label = %ExplorationStatusLabel

var _session: GameSession = null
var _selected_region_id: StringName = &""


func _ready() -> void:
	_confirm_button.pressed.connect(_confirm_exploration)
	_cancel_button.pressed.connect(_cancel_selection)
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
		var progression_system: ProgressionSystem = _session.get_progression_system()
		if not progression_system.raft_upgraded.is_connected(_on_progression_changed):
			progression_system.raft_upgraded.connect(_on_progression_changed)
		var survival_system: SurvivalSystem = _session.get_survival_system()
		if not survival_system.survival_changed.is_connected(_on_survival_changed):
			survival_system.survival_changed.connect(_on_survival_changed)
	_refresh()


func _select_region(region_id: StringName) -> void:
	_selected_region_id = region_id
	_refresh()


func _confirm_exploration() -> void:
	if _session == null or _selected_region_id == &"":
		return
	var result: CommandResult = _session.execute_command(ExploreRegionCommand.new(_selected_region_id))
	_status_label.text = result.message
	if result.succeeded:
		_selected_region_id = &""
	_refresh()


func _cancel_selection() -> void:
	_selected_region_id = &""
	_status_label.text = GameText.get_text(&"ui.world_map.returned")
	_refresh()


func _on_exploration_completed(result: ExplorationResult) -> void:
	_status_label.text = result.message
	_selected_region_id = &""
	_refresh()


func _on_building_changed(_instance_id: StringName, _building_id: StringName, _origin: Vector2i) -> void:
	_refresh()


func _on_building_upgraded(_instance_id: StringName, _new_level: int) -> void:
	_refresh()


func _on_progression_changed(_new_level: int) -> void:
	_refresh()


func _on_survival_changed(_supply: float, _durability: float, _stamina: int) -> void:
	_refresh()


func refresh() -> void:
	_refresh()


func _refresh() -> void:
	if not is_instance_valid(_current_region_label):
		return
	for child: Node in _region_buttons.get_children():
		child.queue_free()
	_confirm_button.disabled = true
	_cancel_button.disabled = _selected_region_id == &""
	if _session == null or not _session.has_active_state():
		_current_region_label.text = GameText.get_text(&"ui.world_map.current_empty")
		_preview_label.text = GameText.get_text(&"ui.world_map.start_hint")
		return

	var world_state: WorldState = _session.get_world_state()
	var current_region: RegionDefinition = _session.get_region_definition(world_state.current_region_id)
	_current_region_label.text = GameText.format(&"ui.world_map.current", [
		current_region.get_display_name(),
		current_region.coordinate.x,
		current_region.coordinate.y,
	])
	var reachable_regions: Array[RegionDefinition] = _session.get_reachable_regions()
	var selected_is_reachable: bool = false
	for region: RegionDefinition in reachable_regions:
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2(0.0, 44.0)
		button.text = GameText.format(&"ui.world_map.region_button", [
			region.get_display_name(),
			region.coordinate.x,
			region.coordinate.y,
			GameText.get_text(&"ui.world_map.charted" if world_state.is_discovered(region.id) else &"ui.world_map.uncharted"),
		])
		button.pressed.connect(_select_region.bind(region.id))
		_region_buttons.add_child(button)
		if region.id == _selected_region_id:
			selected_is_reachable = true
	if not selected_is_reachable:
		_selected_region_id = &""
		_preview_label.text = GameText.get_text(&"ui.world_map.preview_hint")
		_cancel_button.disabled = true
		return
	var selected_region: RegionDefinition = _session.get_region_definition(_selected_region_id)
	var survival_state: SurvivalState = _session.get_survival_state()
	var action_check: SurvivalActionResult = _session.can_perform_survival_action(SurvivalSystem.ACTION_EXPLORE)
	var is_unlocked: bool = _session.is_exploration_unlocked()
	_preview_label.text = GameText.format(&"ui.world_map.preview", [
		selected_region.get_display_name(),
		action_check.stamina_cost,
		survival_state.stamina,
		GameText.get_text(&"ui.world_map.ready") if is_unlocked and action_check.succeeded else (GameText.get_text(&"ui.world_map.build_rudder") if not is_unlocked else action_check.message),
	])
	_confirm_button.disabled = not is_unlocked or not action_check.succeeded
