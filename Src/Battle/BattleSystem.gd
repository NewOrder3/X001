class_name BattleSystem
extends RefCounted

## Pure deterministic turn rules. Session owns cross-module settlement.

signal battle_started(boss_id: StringName)
signal battle_action_resolved(actor_id: StringName, did_use_skill: bool)
signal battle_completed(boss_id: StringName, did_win: bool)

const BATTLE_STREAM_ID: StringName = &"battle"
const ERROR_INVALID_STATE: StringName = &"invalid_battle_state"
const ERROR_UNKNOWN_BOSS: StringName = &"unknown_boss"
const ERROR_EMPTY_LINEUP: StringName = &"empty_lineup"
const ERROR_BATTLE_ACTIVE: StringName = &"battle_active"
const ERROR_BATTLE_INACTIVE: StringName = &"battle_inactive"
const ERROR_INVALID_ACTOR: StringName = &"invalid_battle_actor"
const ERROR_ACTOR_DEFEATED: StringName = &"actor_defeated"
const ERROR_SKILL_COOLDOWN: StringName = &"skill_on_cooldown"
const ERROR_BATTLE_NOT_COMPLETED: StringName = &"battle_not_completed"

var _data_registry: DataRegistry
var _random_service: RandomService


func _init(new_data_registry: DataRegistry, new_random_service: RandomService) -> void:
	_data_registry = new_data_registry
	_random_service = new_random_service


func start(state: GameState, boss_id: StringName) -> BattleActionResult:
	var validation: BattleActionResult = can_start(state, boss_id)
	if not validation.succeeded:
		return validation
	var party_health: Dictionary[StringName, int] = {}
	for survivor_id: StringName in state.survivor_state.lineup_ids:
		var instance: SurvivorInstance = state.survivor_state.survivors[survivor_id]
		var definition: SurvivorDefinition = _data_registry.get_survivor(survivor_id)
		party_health[survivor_id] = definition.battle_max_health + (instance.level - 1) * 3
	var boss: BossDefinition = _data_registry.get_boss(boss_id)
	state.battle_state.status = BattleState.Status.ACTIVE
	state.battle_state.boss_id = boss_id
	state.battle_state.boss_current_health = boss.max_health
	state.battle_state.party_health = party_health
	state.battle_state.skill_cooldowns.clear()
	state.battle_state.turn_number = 0
	state.battle_state.did_win = false
	state.battle_state.settlement_applied = false
	battle_started.emit(boss_id)
	return BattleActionResult.success(GameText.format(&"message.battle.started", [boss.get_display_name()]))


func can_start(state: GameState, boss_id: StringName) -> BattleActionResult:
	if state == null or state.battle_state == null or state.survivor_state == null:
		return BattleActionResult.failure(ERROR_INVALID_STATE, GameText.get_text(&"message.battle.state_unavailable"))
	if state.battle_state.status != BattleState.Status.IDLE:
		return BattleActionResult.failure(ERROR_BATTLE_ACTIVE, GameText.get_text(&"message.battle.already_active"))
	if _data_registry == null or not _data_registry.has_boss(boss_id):
		return BattleActionResult.failure(ERROR_UNKNOWN_BOSS, GameText.get_text(&"message.battle.unavailable"))
	if state.survivor_state.lineup_ids.is_empty():
		return BattleActionResult.failure(ERROR_EMPTY_LINEUP, GameText.get_text(&"message.battle.lineup_required"))
	for survivor_id: StringName in state.survivor_state.lineup_ids:
		if not state.survivor_state.survivors.has(survivor_id) or not _data_registry.has_survivor(survivor_id):
			return BattleActionResult.failure(ERROR_EMPTY_LINEUP, GameText.get_text(&"message.battle.lineup_required"))
	return BattleActionResult.success("")


func perform_action(state: GameState, actor_id: StringName, use_skill: bool) -> BattleActionResult:
	if state == null or state.battle_state == null or state.survivor_state == null:
		return BattleActionResult.failure(ERROR_INVALID_STATE, GameText.get_text(&"message.battle.state_unavailable"))
	var battle: BattleState = state.battle_state
	if not battle.is_active():
		return BattleActionResult.failure(ERROR_BATTLE_INACTIVE, GameText.get_text(&"message.battle.not_active"))
	if not battle.party_health.has(actor_id) or not state.survivor_state.survivors.has(actor_id) or not _data_registry.has_survivor(actor_id):
		return BattleActionResult.failure(ERROR_INVALID_ACTOR, GameText.get_text(&"message.battle.invalid_actor"))
	if battle.party_health[actor_id] <= 0:
		return BattleActionResult.failure(ERROR_ACTOR_DEFEATED, GameText.get_text(&"message.battle.actor_defeated"))
	var survivor: SurvivorDefinition = _data_registry.get_survivor(actor_id)
	var instance: SurvivorInstance = state.survivor_state.survivors[actor_id]
	var damage: int = survivor.battle_attack + (instance.level - 1)
	var action_name: String = GameText.get_text(&"ui.battle.normal_attack")
	var selected_skill: SkillDefinition = null
	if use_skill:
		selected_skill = _data_registry.get_skill(survivor.skill_id)
		if selected_skill == null:
			return BattleActionResult.failure(ERROR_INVALID_ACTOR, GameText.get_text(&"message.battle.invalid_actor"))
		if battle.skill_cooldowns.get(actor_id, 0) > 0:
			return BattleActionResult.failure(ERROR_SKILL_COOLDOWN, GameText.get_text(&"message.battle.skill_cooldown"))
	_decrement_cooldowns(battle)
	if selected_skill != null:
		action_name = selected_skill.get_display_name()
		battle.skill_cooldowns[actor_id] = selected_skill.cooldown_turns
		if selected_skill.effect_type == SkillDefinition.EffectType.HEAL:
			var maximum_health: int = survivor.battle_max_health + (instance.level - 1) * 3
			battle.party_health[actor_id] = mini(maximum_health, battle.party_health[actor_id] + selected_skill.power)
			return _resolve_enemy_turn(state, actor_id, use_skill, GameText.format(&"message.battle.actor_healed", [survivor.get_display_name(), action_name, selected_skill.power]))
		damage += selected_skill.power
	battle.boss_current_health = maxi(battle.boss_current_health - damage, 0)
	if battle.boss_current_health <= 0:
		return _complete(state, actor_id, use_skill, true, GameText.format(&"message.battle.boss_defeated", [survivor.get_display_name(), action_name, damage]))
	return _resolve_enemy_turn(state, actor_id, use_skill, GameText.format(&"message.battle.actor_attacked", [survivor.get_display_name(), action_name, damage]))


func dismiss_completed(state: GameState) -> BattleActionResult:
	if state == null or state.battle_state == null:
		return BattleActionResult.failure(ERROR_INVALID_STATE, GameText.get_text(&"message.battle.state_unavailable"))
	if state.battle_state.status != BattleState.Status.COMPLETED:
		return BattleActionResult.failure(ERROR_BATTLE_NOT_COMPLETED, GameText.get_text(&"message.battle.not_completed"))
	state.battle_state.clear()
	return BattleActionResult.success(GameText.get_text(&"message.battle.returned"))


func validate_loaded_state(state: GameState) -> bool:
	if state == null or state.battle_state == null:
		return false
	var battle: BattleState = state.battle_state
	if battle.status == BattleState.Status.IDLE:
		return true
	if _data_registry == null or not _data_registry.has_boss(battle.boss_id) or battle.party_health.is_empty():
		return false
	for survivor_id: StringName in battle.party_health:
		if not state.survivor_state.survivors.has(survivor_id) or not _data_registry.has_survivor(survivor_id):
			return false
	return true


func _resolve_enemy_turn(state: GameState, actor_id: StringName, use_skill: bool, action_message: String) -> BattleActionResult:
	var battle: BattleState = state.battle_state
	var living_ids: Array[StringName] = []
	for survivor_id: StringName in battle.party_health:
		if battle.party_health[survivor_id] > 0:
			living_ids.append(survivor_id)
	if living_ids.is_empty():
		return _complete(state, actor_id, use_skill, false, action_message)
	living_ids.sort()
	var target_index: int = _random_service.range_i_from_stream(BATTLE_STREAM_ID, 0, living_ids.size() - 1)
	var target_id: StringName = living_ids[target_index]
	var boss: BossDefinition = _data_registry.get_boss(battle.boss_id)
	battle.party_health[target_id] = maxi(battle.party_health[target_id] - boss.attack_damage, 0)
	battle.turn_number += 1
	var target: SurvivorDefinition = _data_registry.get_survivor(target_id)
	var message: String = "%s\n%s" % [action_message, GameText.format(&"message.battle.boss_attacked", [boss.get_display_name(), target.get_display_name(), boss.attack_damage])]
	if _has_living_party_member(battle):
		battle_action_resolved.emit(actor_id, use_skill)
		return BattleActionResult.success(message)
	return _complete(state, actor_id, use_skill, false, message)


func _complete(state: GameState, actor_id: StringName, use_skill: bool, did_win: bool, message: String) -> BattleActionResult:
	var battle: BattleState = state.battle_state
	battle.status = BattleState.Status.COMPLETED
	battle.did_win = did_win
	battle.turn_number += 1
	battle_action_resolved.emit(actor_id, use_skill)
	battle_completed.emit(battle.boss_id, did_win)
	var completion_message: StringName = &"message.battle.victory" if did_win else &"message.battle.defeat"
	return BattleActionResult.success("%s\n%s" % [message, GameText.get_text(completion_message)], true, did_win)


func _has_living_party_member(battle: BattleState) -> bool:
	for health: int in battle.party_health.values():
		if health > 0:
			return true
	return false


func _decrement_cooldowns(battle: BattleState) -> void:
	for survivor_id: StringName in battle.skill_cooldowns:
		battle.skill_cooldowns[survivor_id] = maxi(battle.skill_cooldowns[survivor_id] - 1, 0)
