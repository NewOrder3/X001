class_name BattlePreparationCard
extends PanelContainer

## Modal battle preflight. It only reads Session state and emits the next intent.

signal start_requested(boss_id: StringName)
signal navigate_requested(panel_id: StringName)
signal close_requested

@onready var _title_label: Label = %BattlePreparationTitle
@onready var _summary_label: Label = %BattlePreparationSummary
@onready var _checklist_label: Label = %BattlePreparationChecklist
@onready var _primary_button: Button = %BattlePreparationPrimaryButton
@onready var _later_button: Button = %BattlePreparationLaterButton

var _session: GameSession = null
var _boss_id: StringName = &""
var _recommended_panel_id: StringName = &""
var _is_ready: bool = false


func _ready() -> void:
	_primary_button.pressed.connect(_perform_primary_action)
	_later_button.pressed.connect(close_requested.emit)
	_apply_style()


func bind_session(session: GameSession) -> void:
	_session = session


func show_boss(boss_id: StringName) -> void:
	_boss_id = boss_id
	_refresh()


func _refresh() -> void:
	if _session == null or not _session.has_active_state():
		_title_label.text = GameText.get_text(&"ui.battle.preparation_unavailable")
		_summary_label.text = ""
		_checklist_label.text = ""
		_primary_button.disabled = true
		return
	var boss: BossDefinition = _session.get_boss_definition(_boss_id)
	if boss == null:
		_title_label.text = GameText.get_text(&"message.battle.unavailable")
		_summary_label.text = ""
		_checklist_label.text = ""
		_primary_button.disabled = true
		return
	var survival_state: SurvivalState = _session.get_survival_state()
	var survival_system: SurvivalSystem = _session.get_survival_system()
	var config: SurvivalConfigDefinition = survival_system.get_config(survival_state)
	var lineup_count: int = _session.get_survivor_state().lineup_ids.size()
	var has_lineup: bool = lineup_count > 0
	var has_durability: bool = survival_state != null and survival_state.durability > 0.0
	var has_stamina: bool = survival_state != null and config != null and survival_state.stamina >= config.battle_stamina_cost
	_title_label.text = GameText.format(&"ui.battle.preparation_title", [boss.get_display_name()])
	_summary_label.text = GameText.format(&"ui.battle.preparation_summary", [boss.attack_damage, boss.victory_durability_loss, boss.defeat_durability_loss])
	_checklist_label.text = GameText.format(&"ui.battle.preparation_checklist", [
		_get_checkmark(has_lineup), lineup_count,
		_get_checkmark(has_durability), survival_state.durability if survival_state != null else 0.0,
		_get_checkmark(has_stamina), survival_state.stamina if survival_state != null else 0, config.battle_stamina_cost if config != null else 0,
	])
	_is_ready = has_lineup and has_durability and has_stamina
	_recommended_panel_id = _get_recommended_panel(has_lineup, has_durability, has_stamina)
	_primary_button.disabled = false
	_primary_button.text = GameText.get_text(&"ui.battle.preparation_start" if _is_ready else _get_recommended_action_key())
	_later_button.text = GameText.get_text(&"ui.battle.preparation_later")


func _get_checkmark(is_ready: bool) -> String:
	return GameText.get_text(&"ui.battle.check_ready" if is_ready else &"ui.battle.check_missing")


func _get_recommended_panel(has_lineup: bool, has_durability: bool, has_stamina: bool) -> StringName:
	if not has_lineup:
		return &"crew"
	if not has_durability:
		return &"build"
	if not has_stamina:
		return &"supply"
	return &""


func _get_recommended_action_key() -> StringName:
	match _recommended_panel_id:
		&"crew":
			return &"ui.battle.preparation_crew"
		&"build":
			return &"ui.battle.preparation_repair"
		&"supply":
			return &"ui.battle.preparation_recover"
	return &"ui.battle.preparation_start"


func _perform_primary_action() -> void:
	if _is_ready:
		start_requested.emit(_boss_id)
	elif _recommended_panel_id != &"":
		navigate_requested.emit(_recommended_panel_id)


func _apply_style() -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.13, 0.98)
	style.border_color = Color(0.92, 0.46, 0.30, 0.94)
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	add_theme_stylebox_override(&"panel", style)
