class_name BattleRoot
extends Node

## Battle presentation only. All authority remains in GameSession and BattleSystem.

const BATTLE_BACKGROUND_TEXTURE: Texture2D = preload("res://Assets/Temp/battle/battle_bg_scene_01.png")
const BOSS_TEXTURE: Texture2D = preload("res://Assets/Temp/battle/battle_boss_abyssal.png")

var _session: GameSession = null
var _context: Variant = null
var _status_label: Label = null
var _party_actions: VBoxContainer = null
var _return_button: Button = null


func _ready() -> void:
	_build_view()
	_refresh()


func bind_context(session: GameSession, context: Variant) -> void:
	_session = session
	_context = context
	_refresh()


func get_session() -> GameSession:
	return _session


func _build_view() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	add_child(layer)
	var background: TextureRect = TextureRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.texture = BATTLE_BACKGROUND_TEXTURE
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(background)
	var shade: ColorRect = ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.02, 0.04, 0.08, 0.42)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(shade)
	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-300, -260)
	panel.size = Vector2(600, 520)
	layer.add_child(panel)
	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)
	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)
	var header: HBoxContainer = HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(header)
	var title_and_status: VBoxContainer = VBoxContainer.new()
	title_and_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_and_status)
	var title: Label = Label.new()
	title.text = GameText.get_text(&"ui.battle.title")
	title.add_theme_font_size_override("font_size", 26)
	title_and_status.add_child(title)
	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.custom_minimum_size = Vector2(0, 100)
	title_and_status.add_child(_status_label)
	var boss_art: TextureRect = TextureRect.new()
	boss_art.custom_minimum_size = Vector2(110.0, 160.0)
	boss_art.texture = BOSS_TEXTURE
	boss_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	boss_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	boss_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(boss_art)
	_party_actions = VBoxContainer.new()
	_party_actions.add_theme_constant_override("separation", 8)
	content.add_child(_party_actions)
	_return_button = Button.new()
	_return_button.text = GameText.get_text(&"ui.battle.return")
	_return_button.visible = false
	_return_button.pressed.connect(_return_to_game)
	content.add_child(_return_button)


func _refresh() -> void:
	if _status_label == null:
		return
	_clear_actions()
	if _session == null or not _session.has_active_state():
		_status_label.text = GameText.get_text(&"message.battle.state_unavailable")
		return
	var battle: BattleState = _session.get_battle_state()
	if battle == null or battle.status == BattleState.Status.IDLE:
		_status_label.text = GameText.get_text(&"message.battle.not_active")
		return
	var boss: BossDefinition = _session.get_boss_definition(battle.boss_id)
	if boss == null:
		_status_label.text = GameText.get_text(&"message.battle.unavailable")
		return
	_status_label.text = GameText.format(&"ui.battle.status", [boss.get_display_name(), battle.boss_current_health, boss.max_health, battle.turn_number])
	for survivor_id: StringName in battle.party_health:
		_add_actor_actions(battle, survivor_id)
	if battle.status == BattleState.Status.COMPLETED:
		var last_result: BattleActionResult = _session.get_last_battle_action_result()
		if last_result != null:
			_status_label.text = "%s\n%s" % [_status_label.text, last_result.message]
		_return_button.visible = true


func _add_actor_actions(battle: BattleState, survivor_id: StringName) -> void:
	var definition: SurvivorDefinition = _session.get_survivor_definition(survivor_id)
	var instance: SurvivorInstance = _session.get_survivor_state().survivors.get(survivor_id)
	if definition == null or instance == null:
		return
	var maximum_health: int = definition.battle_max_health + (instance.level - 1) * 3
	var row: VBoxContainer = VBoxContainer.new()
	var health_label: Label = Label.new()
	health_label.text = GameText.format(&"ui.battle.party_member", [definition.get_display_name(), battle.party_health[survivor_id], maximum_health])
	row.add_child(health_label)
	if battle.status != BattleState.Status.ACTIVE:
		_party_actions.add_child(row)
		return
	var actions: HBoxContainer = HBoxContainer.new()
	var attack_button: Button = Button.new()
	attack_button.text = GameText.get_text(&"ui.battle.normal_attack")
	attack_button.disabled = battle.party_health[survivor_id] <= 0
	attack_button.pressed.connect(_act.bind(survivor_id, false))
	actions.add_child(attack_button)
	var skill: SkillDefinition = _session.get_skill_definition(definition.skill_id)
	var skill_button: Button = Button.new()
	skill_button.text = GameText.format(&"ui.battle.use_skill", [skill.get_display_name() if skill != null else String(definition.skill_id)])
	skill_button.disabled = battle.party_health[survivor_id] <= 0 or battle.skill_cooldowns.get(survivor_id, 0) > 0
	skill_button.pressed.connect(_act.bind(survivor_id, true))
	actions.add_child(skill_button)
	row.add_child(actions)
	_party_actions.add_child(row)


func _act(survivor_id: StringName, use_skill: bool) -> void:
	if _session == null:
		return
	var result: CommandResult = _session.execute_command(BattleActionCommand.new(survivor_id, use_skill))
	if not result.succeeded and _status_label != null:
		_status_label.text = result.message
	_refresh()


func _return_to_game() -> void:
	if _session == null:
		return
	var result: CommandResult = _session.execute_command(ReturnFromBattleCommand.new())
	if not result.succeeded and _status_label != null:
		_status_label.text = result.message


func _clear_actions() -> void:
	if _party_actions == null:
		return
	for child: Node in _party_actions.get_children():
		child.queue_free()
