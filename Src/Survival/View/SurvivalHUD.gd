class_name SurvivalHUD
extends PanelContainer

## Read-only S2 HUD. It observes SurvivalSystem and never mutates game state.

@onready var _supply_label: Label = %SupplyLabel
@onready var _durability_label: Label = %DurabilityLabel
@onready var _stamina_label: Label = %StaminaLabel
@onready var _status_label: Label = %SurvivalStatusLabel

var _session: GameSession = null
var _survival_system: SurvivalSystem = null


func bind_session(session: GameSession) -> void:
	_session = session
	_survival_system = _session.get_survival_system() if _session != null else null
	if _survival_system != null and not _survival_system.survival_changed.is_connected(_on_survival_changed):
		_survival_system.survival_changed.connect(_on_survival_changed)
	_refresh()


func _on_survival_changed(_supply: float, _durability: float, _stamina: int) -> void:
	_refresh()


func _refresh() -> void:
	if not is_instance_valid(_supply_label):
		return
	if _session == null or not _session.has_active_state() or _survival_system == null:
		_supply_label.text = "补给：--"
		_durability_label.text = "耐久：--"
		_stamina_label.text = "体力：--"
		_status_label.text = ""
		return

	var state: SurvivalState = _session.get_survival_state()
	var config: SurvivalConfigDefinition = _survival_system.get_config(state)
	if state == null or config == null:
		return
	_supply_label.text = "补给：%.1f / %.0f" % [state.supply, config.max_supply]
	_durability_label.text = "耐久：%.1f / %.0f" % [state.durability, config.max_durability]
	_stamina_label.text = "体力：%d / %d" % [state.stamina, config.max_stamina]
	_supply_label.modulate = _get_status_color(state.supply_status)
	_durability_label.modulate = _get_status_color(state.durability_status)
	_stamina_label.modulate = _get_status_color(state.stamina_status)
	_status_label.text = _get_status_message(state)


func _get_status_color(status: SurvivalState.IndicatorStatus) -> Color:
	if status == SurvivalState.IndicatorStatus.DEPLETED:
		return Color("b9b9b9")
	if status == SurvivalState.IndicatorStatus.WARNING:
		return Color("ffb55c")
	return Color.WHITE


func _get_status_message(state: SurvivalState) -> String:
	var messages: PackedStringArray = []
	if state.supply_status == SurvivalState.IndicatorStatus.DEPLETED:
		messages.append("补给耗尽：手动操作效率降低")
	elif state.supply_status == SurvivalState.IndicatorStatus.WARNING:
		messages.append("补给不足")
	if state.durability_status == SurvivalState.IndicatorStatus.DEPLETED:
		messages.append("耐久耗尽：无法进入战斗")
	elif state.durability_status == SurvivalState.IndicatorStatus.WARNING:
		messages.append("耐久偏低")
	if state.stamina_status == SurvivalState.IndicatorStatus.DEPLETED:
		messages.append("体力耗尽：无法探索或战斗")
	elif state.stamina_status == SurvivalState.IndicatorStatus.WARNING:
		messages.append("体力偏低")
	return "\n".join(messages)
