class_name ExplorationResultCard
extends PanelContainer

## Modal voyage summary. It translates a completed exploration result into one
## clear next action without changing gameplay state.

signal result_ready
signal navigate_requested(panel_id: StringName)
signal close_requested

@onready var _title_label: Label = %ExplorationResultTitle
@onready var _summary_label: Label = %ExplorationResultSummary
@onready var _details_label: Label = %ExplorationResultDetails
@onready var _primary_button: Button = %ExplorationResultPrimaryButton
@onready var _later_button: Button = %ExplorationResultLaterButton

var _session: GameSession = null
var _next_panel_id: StringName = &"map"


func _ready() -> void:
	_primary_button.pressed.connect(_open_recommended_panel)
	_later_button.pressed.connect(close_requested.emit)
	_apply_style()


func bind_session(session: GameSession) -> void:
	_session = session
	if _session == null:
		return
	var exploration_system: ExplorationSystem = _session.get_exploration_system()
	if not exploration_system.exploration_completed.is_connected(_on_exploration_completed):
		exploration_system.exploration_completed.connect(_on_exploration_completed)


func _on_exploration_completed(result: ExplorationResult) -> void:
	if result == null or not result.succeeded:
		return
	_show_result(result)
	result_ready.emit()


func _show_result(result: ExplorationResult) -> void:
	if _session == null:
		return
	var target_region: RegionDefinition = _session.get_region_definition(result.target_region_id)
	var region_name: String = target_region.get_display_name() if target_region != null else String(result.target_region_id)
	_title_label.text = GameText.format(&"ui.exploration_result.arrival", [region_name])
	_summary_label.text = result.message
	_details_label.text = _format_details(result)
	_next_panel_id = _get_recommended_panel(result)
	_primary_button.text = _get_recommended_action_text(result)
	_later_button.text = GameText.get_text(&"ui.exploration_result.later")


func _open_recommended_panel() -> void:
	navigate_requested.emit(_next_panel_id)


func _get_recommended_panel(result: ExplorationResult) -> StringName:
	if result.rescued_survivor_id != &"":
		return &"crew"
	if result.durability_loss > 0.0:
		return &"build"
	return &"map"


func _get_recommended_action_text(result: ExplorationResult) -> String:
	if result.rescued_survivor_id != &"":
		return GameText.get_text(&"ui.exploration_result.view_survivor")
	if result.durability_loss > 0.0:
		return GameText.get_text(&"ui.exploration_result.repair_raft")
	return GameText.get_text(&"ui.exploration_result.continue_sailing")


func _format_details(result: ExplorationResult) -> String:
	var lines: PackedStringArray = []
	if not result.reward_items.is_empty():
		var rewards: PackedStringArray = []
		for item_id: StringName in result.reward_items:
			var item: ItemDefinition = _session.get_item_definition(item_id)
			rewards.append(GameText.format(&"ui.exploration_result.reward_entry", [item.get_display_name() if item != null else String(item_id), result.reward_items[item_id]]))
		lines.append(GameText.format(&"ui.exploration_result.rewards", ["、".join(rewards)]))
	if result.durability_loss > 0.0:
		lines.append(GameText.format(&"ui.exploration_result.durability_loss", [result.durability_loss]))
	if result.rescued_survivor_id != &"":
		var survivor: SurvivorDefinition = _session.get_survivor_definition(result.rescued_survivor_id)
		lines.append(GameText.format(&"ui.exploration_result.rescue", [survivor.get_display_name() if survivor != null else String(result.rescued_survivor_id)]))
	lines.append(GameText.format(&"ui.exploration_result.stamina_cost", [result.stamina_cost]))
	return "\n".join(lines)


func _apply_style() -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.10, 0.14, 0.97)
	style.border_color = Color(0.90, 0.68, 0.32, 0.92)
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	add_theme_stylebox_override(&"panel", style)
