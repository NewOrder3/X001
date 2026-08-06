class_name SurvivorPanel
extends PanelContainer

## Card and lineup input surface. It submits Commands and reads public session queries only.

@onready var _pending_cards: VBoxContainer = %PendingCards
@onready var _lineup_label: Label = %LineupLabel
@onready var _owned_cards: VBoxContainer = %OwnedCards
@onready var _status_label: Label = %SurvivorStatusLabel
@onready var _challenge_boss_button: Button = %ChallengeBossButton

const PORTRAIT_BY_SURVIVOR_ID := {
	&"survivor_bo": preload("res://Assets/Temp/partner/partner_portrait_01.png"),
	&"survivor_marin": preload("res://Assets/Temp/partner/partner_portrait_02.png"),
	&"survivor_su": preload("res://Assets/Temp/partner/partner_portrait_03.png"),
	&"survivor_yue": preload("res://Assets/Temp/partner/partner_portrait_04.png"),
}

var _session: GameSession = null


func _ready() -> void:
	_challenge_boss_button.pressed.connect(_challenge_boss)
	_refresh()


func bind_session(session: GameSession) -> void:
	_session = session
	if _session != null:
		var survivor_system: SurvivorSystem = _session.get_survivor_system()
		if not survivor_system.recruitment_offered.is_connected(_on_roster_changed):
			survivor_system.recruitment_offered.connect(_on_roster_changed)
		if not survivor_system.survivor_recruited.is_connected(_on_roster_changed):
			survivor_system.survivor_recruited.connect(_on_roster_changed)
		if not survivor_system.survivor_upgraded.is_connected(_on_survivor_upgraded):
			survivor_system.survivor_upgraded.connect(_on_survivor_upgraded)
		if not survivor_system.lineup_changed.is_connected(_on_lineup_changed):
			survivor_system.lineup_changed.connect(_on_lineup_changed)
	_refresh()


func _refresh() -> void:
	if not is_instance_valid(_pending_cards):
		return
	_clear_children(_pending_cards)
	_clear_children(_owned_cards)
	if _session == null or not _session.has_active_state():
		_challenge_boss_button.disabled = true
		_lineup_label.text = GameText.format(&"ui.survivor.lineup", [0, SurvivorState.MAX_LINEUP_SIZE, GameText.get_text(&"ui.survivor.lineup_empty")])
		_add_empty_label(_pending_cards, &"ui.survivor.pending_empty")
		_add_empty_label(_owned_cards, &"ui.survivor.roster_empty")
		return

	var state: SurvivorState = _session.get_survivor_state()
	_challenge_boss_button.disabled = state.lineup_ids.is_empty()
	var lineup_names: PackedStringArray = []
	for survivor_id: StringName in state.lineup_ids:
		var definition: SurvivorDefinition = _session.get_survivor_definition(survivor_id)
		if definition != null:
			lineup_names.append(definition.get_display_name())
	var lineup_text: String = "、".join(lineup_names)
	if lineup_text.is_empty():
		lineup_text = GameText.get_text(&"ui.survivor.lineup_empty")
	_lineup_label.text = GameText.format(&"ui.survivor.lineup", [state.lineup_ids.size(), SurvivorState.MAX_LINEUP_SIZE, lineup_text])

	if state.pending_recruitment_ids.is_empty():
		_add_empty_label(_pending_cards, &"ui.survivor.pending_empty")
	else:
		for survivor_id: StringName in state.pending_recruitment_ids:
			var definition: SurvivorDefinition = _session.get_survivor_definition(survivor_id)
			if definition == null:
				continue
			var recruit_button: Button = Button.new()
			recruit_button.text = GameText.format(&"ui.survivor.recruit", [definition.get_display_name()])
			_apply_portrait(recruit_button, survivor_id)
			recruit_button.pressed.connect(_recruit.bind(survivor_id))
			_pending_cards.add_child(recruit_button)

	var owned_survivors: Array[SurvivorInstance] = _session.get_survivor_system().get_owned_survivors(state)
	if owned_survivors.is_empty():
		_add_empty_label(_owned_cards, &"ui.survivor.roster_empty")
		return
	for instance: SurvivorInstance in owned_survivors:
		_add_survivor_card(state, instance)


func _add_survivor_card(state: SurvivorState, instance: SurvivorInstance) -> void:
	var definition: SurvivorDefinition = _session.get_survivor_definition(instance.survivor_id)
	if definition == null:
		return
	var skill: SkillDefinition = _session.get_skill_definition(definition.skill_id)
	var card: HBoxContainer = HBoxContainer.new()
	card.add_theme_constant_override("separation", 10)
	var portrait: TextureRect = TextureRect.new()
	portrait.custom_minimum_size = Vector2(72.0, 72.0)
	portrait.texture = PORTRAIT_BY_SURVIVOR_ID.get(instance.survivor_id) as Texture2D
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(portrait)
	var details: VBoxContainer = VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 4)
	card.add_child(details)
	var card_label: Label = Label.new()
	card_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card_label.text = GameText.format(&"ui.survivor.card", [
		definition.get_display_name(),
		instance.level,
		definition.get_description(),
		skill.get_display_name() if skill != null else String(definition.skill_id),
		String(definition.passive_id),
		definition.passive_value_per_level,
	])
	details.add_child(card_label)
	var actions: HBoxContainer = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 6)
	var upgrade_button: Button = Button.new()
	upgrade_button.text = GameText.format(&"ui.survivor.upgrade", [_format_cost(definition.upgrade_cost)])
	upgrade_button.disabled = instance.level >= SurvivorSystem.MAX_LEVEL
	upgrade_button.pressed.connect(_upgrade.bind(instance.survivor_id))
	actions.add_child(upgrade_button)
	var lineup_button: Button = Button.new()
	var is_in_lineup: bool = state.lineup_ids.has(instance.survivor_id)
	lineup_button.text = GameText.get_text(&"ui.survivor.remove_from_lineup" if is_in_lineup else &"ui.survivor.add_to_lineup")
	lineup_button.pressed.connect(_toggle_lineup.bind(instance.survivor_id))
	actions.add_child(lineup_button)
	details.add_child(actions)
	_owned_cards.add_child(card)


func _recruit(survivor_id: StringName) -> void:
	_submit(RecruitSurvivorCommand.new(survivor_id))


func _upgrade(survivor_id: StringName) -> void:
	_submit(UpgradeSurvivorCommand.new(survivor_id))


func _toggle_lineup(survivor_id: StringName) -> void:
	if _session == null:
		return
	var lineup_ids: Array[StringName] = _session.get_survivor_state().lineup_ids.duplicate()
	if lineup_ids.has(survivor_id):
		lineup_ids.erase(survivor_id)
	else:
		lineup_ids.append(survivor_id)
	_submit(SetLineupCommand.new(lineup_ids))


func _challenge_boss() -> void:
	_submit(StartBattleCommand.new(&"boss_tutorial_sea_beast"))


func _submit(command: GameCommand) -> void:
	if _session == null:
		return
	var result: CommandResult = _session.execute_command(command)
	_status_label.text = result.message
	_refresh()


func _on_roster_changed(_survivor_id: StringName) -> void:
	_refresh()


func _on_survivor_upgraded(_survivor_id: StringName, _level: int) -> void:
	_refresh()


func _on_lineup_changed(_lineup_ids: Array[StringName]) -> void:
	_refresh()


func _add_empty_label(container: VBoxContainer, text_key: StringName) -> void:
	var label: Label = Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = GameText.get_text(text_key)
	container.add_child(label)


func _apply_portrait(button: Button, survivor_id: StringName) -> void:
	button.icon = PORTRAIT_BY_SURVIVOR_ID.get(survivor_id) as Texture2D
	button.expand_icon = true
	button.icon_max_width = 42


func _clear_children(container: VBoxContainer) -> void:
	for child: Node in container.get_children():
		child.queue_free()


func _format_cost(cost: Dictionary[StringName, int]) -> String:
	var parts: PackedStringArray = []
	for item_id: StringName in cost:
		var item: ItemDefinition = _session.get_item_definition(item_id)
		parts.append("%s×%d" % [item.get_display_name() if item != null else String(item_id), cost[item_id]])
	return "、".join(parts)
