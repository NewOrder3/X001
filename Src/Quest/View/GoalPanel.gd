class_name GoalPanel
extends PanelContainer

## New-player goal list with one-tap navigation into the related panel.

signal navigate_requested(panel_id: StringName)
signal battle_requested(boss_id: StringName)

@onready var _goal_list: VBoxContainer = %GoalList
@onready var _status_label: Label = %GoalStatusLabel

var _session: GameSession = null


func _ready() -> void:
	_refresh()


func bind_session(session: GameSession) -> void:
	_session = session
	if _session == null:
		_refresh()
		return
	_bind_signal(_session.get_building_system().building_placed, _on_progress_changed)
	_bind_signal(_session.get_building_system().building_upgraded, _on_progress_changed)
	_bind_signal(_session.get_progression_system().raft_upgraded, _on_progress_changed)
	_bind_signal(_session.get_inventory_system().item_amount_changed, _on_progress_changed)
	_bind_signal(_session.get_survivor_system().survivor_recruited, _on_progress_changed)
	_bind_signal(_session.get_survivor_system().lineup_changed, _on_progress_changed)
	_bind_signal(_session.get_exploration_system().exploration_completed, _on_progress_changed)
	_bind_signal(_session.get_battle_system().battle_completed, _on_progress_changed)
	_refresh()


func _bind_signal(signal_to_bind: Signal, callable: Callable) -> void:
	if not signal_to_bind.is_connected(callable):
		signal_to_bind.connect(callable)


func _on_progress_changed(_a: Variant = null, _b: Variant = null, _c: Variant = null, _d: Variant = null) -> void:
	_refresh()


func _refresh() -> void:
	if not is_instance_valid(_goal_list):
		return
	for child: Node in _goal_list.get_children():
		child.queue_free()
	if _session == null or not _session.has_active_state():
		_status_label.text = GameText.get_text(&"ui.goal.status_initial")
		return
	var quests: Array[QuestDefinition] = _session.get_active_quests()
	if quests.is_empty():
		var done_label: Label = Label.new()
		done_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		done_label.text = GameText.get_text(&"ui.goal.all_done")
		_goal_list.add_child(done_label)
		_status_label.text = ""
		return
	_status_label.text = GameText.get_text(&"ui.goal.status_hint")
	for quest: QuestDefinition in quests:
		var progress: int = _session.get_quest_progress(quest.id)
		var card: VBoxContainer = VBoxContainer.new()
		card.add_theme_constant_override("separation", 4)
		var title: Label = Label.new()
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title.text = GameText.format(&"ui.goal.title", [quest.get_display_name(), progress, quest.target_amount])
		card.add_child(title)
		var description: Label = Label.new()
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.text = quest.get_description()
		card.add_child(description)
		var action: Button = Button.new()
		action.custom_minimum_size = Vector2(0.0, 44.0)
		var is_battle_goal: bool = quest.objective_type == QuestDefinition.ObjectiveType.WIN_BATTLE
		action.text = GameText.get_text(&"ui.current_goal.challenge" if is_battle_goal else &"ui.goal.navigate")
		if is_battle_goal:
			action.pressed.connect(battle_requested.emit.bind(quest.target_id))
		else:
			action.pressed.connect(navigate_requested.emit.bind(_get_panel_id(quest)))
		card.add_child(action)
		_goal_list.add_child(card)


func _get_panel_id(quest: QuestDefinition) -> StringName:
	match quest.objective_type:
		QuestDefinition.ObjectiveType.BUILD_BUILDING, QuestDefinition.ObjectiveType.UPGRADE_RAFT:
			return &"build"
		QuestDefinition.ObjectiveType.HAVE_ITEM:
			return &"supply"
		QuestDefinition.ObjectiveType.RECRUIT_SURVIVOR, QuestDefinition.ObjectiveType.WIN_BATTLE:
			return &"crew"
		QuestDefinition.ObjectiveType.EXPLORE_REGION:
			return &"map"
	return &""
