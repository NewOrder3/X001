class_name QuestFeedbackBanner
extends PanelContainer

## Presentation-only completion feedback driven by QuestSystem domain signals.

@onready var _label: Label = %QuestFeedbackLabel

var _session: GameSession = null
var _hide_timer: Timer = null


func _ready() -> void:
	_hide_timer = Timer.new()
	_hide_timer.one_shot = true
	_hide_timer.timeout.connect(hide)
	add_child(_hide_timer)
	hide()


func bind_session(session: GameSession) -> void:
	_session = session
	if _session == null:
		return
	var quest_system: QuestSystem = _session.get_quest_system()
	if not quest_system.quest_completed.is_connected(_on_quest_completed):
		quest_system.quest_completed.connect(_on_quest_completed)


func _on_quest_completed(quest_id: StringName) -> void:
	if _session == null or not is_instance_valid(_label):
		return
	var completed_quest: QuestDefinition = _session.get_quest_definition(quest_id)
	if completed_quest == null:
		return
	var next_quest: QuestDefinition = _session.get_current_quest()
	var next_text: String = next_quest.get_display_name() if next_quest != null else GameText.get_text(&"ui.current_goal.complete")
	_label.text = GameText.format(&"ui.quest_feedback.completed", [completed_quest.get_display_name(), next_text])
	show()
	_hide_timer.start(3.6)
