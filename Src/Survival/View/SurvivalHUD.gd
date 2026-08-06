class_name SurvivalHUD
extends PanelContainer

## Read-only S2 HUD. It observes SurvivalSystem and never mutates game state.

signal navigate_requested(panel_id: StringName)
signal display_mode_changed(is_expanded: bool)

@onready var _summary_label: Label = %SurvivalSummaryLabel
@onready var _status_label: Label = %SurvivalStatusLabel
@onready var _warning_action_button: Button = %SurvivalWarningActionButton

var _session: GameSession = null
var _survival_system: SurvivalSystem = null
var _is_expanded: bool = false
var _recommended_panel_id: StringName = &""


func _ready() -> void:
	_warning_action_button.pressed.connect(_open_recommended_panel)


func bind_session(session: GameSession) -> void:
	_session = session
	_survival_system = _session.get_survival_system() if _session != null else null
	if _survival_system != null and not _survival_system.survival_changed.is_connected(_on_survival_changed):
		_survival_system.survival_changed.connect(_on_survival_changed)
	_refresh()


func _on_survival_changed(_supply: float, _durability: float, _stamina: int) -> void:
	_refresh()


func _refresh() -> void:
	if not is_instance_valid(_summary_label):
		return
	if _session == null or not _session.has_active_state() or _survival_system == null:
		_summary_label.text = GameText.get_text(&"ui.survival.summary_empty")
		_status_label.text = ""
		_status_label.hide()
		_warning_action_button.hide()
		_set_expanded(false)
		return

	var state: SurvivalState = _session.get_survival_state()
	var config: SurvivalConfigDefinition = _survival_system.get_config(state)
	if state == null or config == null:
		return
	_summary_label.text = GameText.format(&"ui.survival.summary", [state.supply, config.max_supply, state.durability, config.max_durability, state.stamina, config.max_stamina])
	_summary_label.modulate = _get_summary_color(state)
	_status_label.text = _get_status_message(state)
	_status_label.visible = not _status_label.text.is_empty()
	_configure_warning_action(state)
	_set_expanded(not _status_label.text.is_empty())


func is_expanded() -> bool:
	return _is_expanded


func _set_expanded(is_expanded: bool) -> void:
	if _is_expanded == is_expanded:
		return
	_is_expanded = is_expanded
	display_mode_changed.emit(_is_expanded)


func _configure_warning_action(state: SurvivalState) -> void:
	_recommended_panel_id = &""
	if state.supply_status != SurvivalState.IndicatorStatus.NORMAL:
		_recommended_panel_id = &"supply"
		_warning_action_button.text = GameText.get_text(&"ui.survival.action_supply")
	elif state.durability_status != SurvivalState.IndicatorStatus.NORMAL:
		_recommended_panel_id = &"build"
		_warning_action_button.text = GameText.get_text(&"ui.survival.action_repair")
	_warning_action_button.visible = _recommended_panel_id != &""


func _open_recommended_panel() -> void:
	if _recommended_panel_id != &"":
		navigate_requested.emit(_recommended_panel_id)


func _get_summary_color(state: SurvivalState) -> Color:
	if state.supply_status == SurvivalState.IndicatorStatus.DEPLETED or state.durability_status == SurvivalState.IndicatorStatus.DEPLETED or state.stamina_status == SurvivalState.IndicatorStatus.DEPLETED:
		return Color("b9b9b9")
	if state.supply_status == SurvivalState.IndicatorStatus.WARNING or state.durability_status == SurvivalState.IndicatorStatus.WARNING or state.stamina_status == SurvivalState.IndicatorStatus.WARNING:
		return Color("ffb55c")
	return Color.WHITE


func _get_status_message(state: SurvivalState) -> String:
	var messages: PackedStringArray = []
	if state.supply_status == SurvivalState.IndicatorStatus.DEPLETED:
		messages.append(GameText.get_text(&"ui.survival.supply_depleted"))
	elif state.supply_status == SurvivalState.IndicatorStatus.WARNING:
		messages.append(GameText.get_text(&"ui.survival.supply_warning"))
	if state.durability_status == SurvivalState.IndicatorStatus.DEPLETED:
		messages.append(GameText.get_text(&"ui.survival.durability_depleted"))
	elif state.durability_status == SurvivalState.IndicatorStatus.WARNING:
		messages.append(GameText.get_text(&"ui.survival.durability_warning"))
	if state.stamina_status == SurvivalState.IndicatorStatus.DEPLETED:
		messages.append(GameText.get_text(&"ui.survival.stamina_depleted"))
	elif state.stamina_status == SurvivalState.IndicatorStatus.WARNING:
		messages.append(GameText.get_text(&"ui.survival.stamina_warning"))
	return "\n".join(messages)
