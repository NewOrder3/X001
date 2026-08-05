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
	_status_label.text = "Returned to raft planning."
	_refresh()


func _on_exploration_completed(result: ExplorationResult) -> void:
	_status_label.text = result.message
	_selected_region_id = &""
	_refresh()


func _refresh() -> void:
	if not is_instance_valid(_current_region_label):
		return
	for child: Node in _region_buttons.get_children():
		child.queue_free()
	_confirm_button.disabled = true
	_cancel_button.disabled = _selected_region_id == &""
	if _session == null or not _session.has_active_state():
		_current_region_label.text = "Current waters: -"
		_preview_label.text = "Start a game to chart nearby sea regions."
		return

	var world_state: WorldState = _session.get_world_state()
	var current_region: RegionDefinition = _session.get_region_definition(world_state.current_region_id)
	_current_region_label.text = "Current waters: %s (%d, %d)" % [
		current_region.display_name,
		current_region.coordinate.x,
		current_region.coordinate.y,
	]
	var reachable_regions: Array[RegionDefinition] = _session.get_reachable_regions()
	var selected_is_reachable: bool = false
	for region: RegionDefinition in reachable_regions:
		var button: Button = Button.new()
		button.text = "%s  (%d, %d)  %s" % [
			region.display_name,
			region.coordinate.x,
			region.coordinate.y,
			"charted" if world_state.is_discovered(region.id) else "uncharted",
		]
		button.pressed.connect(_select_region.bind(region.id))
		_region_buttons.add_child(button)
		if region.id == _selected_region_id:
			selected_is_reachable = true
	if not selected_is_reachable:
		_selected_region_id = &""
		_preview_label.text = "Choose an adjacent hex to preview the voyage."
		_cancel_button.disabled = true
		return
	var selected_region: RegionDefinition = _session.get_region_definition(_selected_region_id)
	var survival_state: SurvivalState = _session.get_survival_state()
	var action_check: SurvivalActionResult = _session.can_perform_survival_action(SurvivalSystem.ACTION_EXPLORE)
	var is_unlocked: bool = _session.is_exploration_unlocked()
	_preview_label.text = "Voyage to %s costs %d stamina. Current stamina: %d. %s" % [
		selected_region.display_name,
		action_check.stamina_cost,
		survival_state.stamina,
		"Ready to sail." if is_unlocked and action_check.succeeded else ("Build a ship rudder first." if not is_unlocked else action_check.message),
	]
	_confirm_button.disabled = not is_unlocked or not action_check.succeeded
