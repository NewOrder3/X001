class_name CurrentGoalHud
extends PanelContainer

## Persistent primary-goal summary. It only emits navigation intent or battle Commands.

signal navigate_requested(panel_id: StringName)
signal battle_requested(boss_id: StringName)

@onready var _title_label: Label = %CurrentGoalTitleLabel
@onready var _description_label: Label = %CurrentGoalDescriptionLabel
@onready var _action_button: Button = %CurrentGoalActionButton

var _session: GameSession = null


func _ready() -> void:
	_action_button.pressed.connect(_perform_action)
	_refresh()


func bind_session(session: GameSession) -> void:
	_session = session
	if _session != null:
		var quest_system: QuestSystem = _session.get_quest_system()
		if not quest_system.quest_completed.is_connected(_on_quest_completed):
			quest_system.quest_completed.connect(_on_quest_completed)
		if not quest_system.quest_activated.is_connected(_on_quest_activated):
			quest_system.quest_activated.connect(_on_quest_activated)
	_refresh()


func _perform_action() -> void:
	if _session == null:
		return
	var quest: QuestDefinition = _session.get_current_quest()
	if quest == null:
		return
	if quest.objective_type == QuestDefinition.ObjectiveType.WIN_BATTLE:
		if _is_battle_ready():
			battle_requested.emit(quest.target_id)
		else:
			navigate_requested.emit(&"crew")
		return
	navigate_requested.emit(_get_panel_id(quest))


func _on_quest_completed(_quest_id: StringName) -> void:
	_refresh()


func _on_quest_activated(_quest_id: StringName) -> void:
	_refresh()


func _refresh() -> void:
	if not is_instance_valid(_title_label):
		return
	if _session == null or not _session.has_active_state():
		_title_label.text = GameText.get_text(&"ui.current_goal.initial")
		_description_label.text = ""
		_action_button.disabled = true
		return
	var quest: QuestDefinition = _session.get_current_quest()
	if quest == null:
		_title_label.text = GameText.get_text(&"ui.current_goal.complete")
		_description_label.text = ""
		_action_button.disabled = true
		return
	var progress: int = _session.get_quest_progress(quest.id)
	_title_label.text = GameText.format(&"ui.current_goal.title", [quest.get_display_name(), progress, quest.target_amount])
	_description_label.text = quest.get_description()
	_action_button.disabled = false
	if quest.objective_type == QuestDefinition.ObjectiveType.WIN_BATTLE:
		_action_button.text = GameText.get_text(&"ui.current_goal.challenge" if _is_battle_ready() else &"ui.current_goal.prepare_lineup")
	else:
		_action_button.text = GameText.get_text(&"ui.goal.navigate")


func _get_panel_id(quest: QuestDefinition) -> StringName:
	match quest.objective_type:
		QuestDefinition.ObjectiveType.BUILD_BUILDING, QuestDefinition.ObjectiveType.UPGRADE_RAFT:
			return &"build"
		QuestDefinition.ObjectiveType.HAVE_ITEM, QuestDefinition.ObjectiveType.USE_ITEM:
			return &"supply"
		QuestDefinition.ObjectiveType.RECRUIT_SURVIVOR:
			return &"crew"
		QuestDefinition.ObjectiveType.EXPLORE_REGION:
			return &"map" if _session.is_exploration_unlocked() else &"build"
	return &""


func _is_battle_ready() -> bool:
	return _session != null and _session.has_active_state() and not _session.get_survivor_state().lineup_ids.is_empty()
