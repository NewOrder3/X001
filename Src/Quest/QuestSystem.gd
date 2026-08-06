class_name QuestSystem
extends RefCounted

## Sequences new-player goals from immutable Definitions. It only mutates QuestState
## after a successful gameplay command has changed the underlying GameState.

signal quest_completed(quest_id: StringName)
signal quest_activated(quest_id: StringName)

var _data_registry: DataRegistry


func _init(new_data_registry: DataRegistry) -> void:
	_data_registry = new_data_registry


func initialize_new_state(state: QuestState) -> bool:
	if state == null:
		return false
	state.completed_quest_ids.clear()
	state.defeated_boss_ids.clear()
	state.used_item_counts.clear()
	return true


func activate_loaded_state(state: QuestState) -> bool:
	if state == null or _data_registry == null:
		return false
	for quest_id: StringName in state.completed_quest_ids:
		if not _data_registry.has_quest(quest_id):
			return false
	for boss_id: StringName in state.defeated_boss_ids:
		if not _data_registry.has_boss(boss_id):
			return false
	for item_id: StringName in state.used_item_counts:
		if not _data_registry.has_item(item_id) or state.used_item_counts[item_id] <= 0:
			return false
	return true


func get_active_quests(state: GameState) -> Array[QuestDefinition]:
	var quests: Array[QuestDefinition] = []
	if state == null or state.quest_state == null or _data_registry == null:
		return quests
	for quest: QuestDefinition in _data_registry.get_quests():
		if state.quest_state.completed_quest_ids.has(quest.id) or not _are_prerequisites_complete(state.quest_state, quest):
			continue
		_insert_by_sort_order(quests, quest)
	return quests


func get_current_quest(state: GameState) -> QuestDefinition:
	var active_quests: Array[QuestDefinition] = get_active_quests(state)
	return active_quests[0] if not active_quests.is_empty() else null


func evaluate(state: GameState) -> Array[StringName]:
	var completed_ids: Array[StringName] = []
	if state == null or state.quest_state == null:
		return completed_ids
	var previously_active: QuestDefinition = get_current_quest(state)
	while true:
		var current_quest: QuestDefinition = get_current_quest(state)
		if current_quest == null or get_progress(state, current_quest.id) < current_quest.target_amount:
			break
		state.quest_state.completed_quest_ids.append(current_quest.id)
		completed_ids.append(current_quest.id)
		quest_completed.emit(current_quest.id)
	var active_quest: QuestDefinition = get_current_quest(state)
	if active_quest != null and (previously_active == null or active_quest.id != previously_active.id):
		quest_activated.emit(active_quest.id)
	return completed_ids


func is_completed(state: GameState, quest_id: StringName) -> bool:
	return state != null and state.quest_state != null and state.quest_state.completed_quest_ids.has(quest_id)


func get_progress(state: GameState, quest_id: StringName) -> int:
	if state == null or _data_registry == null or not _data_registry.has_quest(quest_id):
		return 0
	var quest: QuestDefinition = _data_registry.get_quest(quest_id)
	match quest.objective_type:
		QuestDefinition.ObjectiveType.BUILD_BUILDING:
			return _count_building(state, quest.target_id)
		QuestDefinition.ObjectiveType.HAVE_ITEM:
			return state.inventory_state.item_amounts.get(quest.target_id, 0)
		QuestDefinition.ObjectiveType.USE_ITEM:
			return state.quest_state.used_item_counts.get(quest.target_id, 0)
		QuestDefinition.ObjectiveType.UPGRADE_RAFT:
			return state.progression_state.raft_level if state.progression_state != null else 0
		QuestDefinition.ObjectiveType.RECRUIT_SURVIVOR:
			if quest.target_id == &"":
				return state.survivor_state.survivors.size()
			return 1 if state.survivor_state.survivors.has(quest.target_id) else 0
		QuestDefinition.ObjectiveType.WIN_BATTLE:
			return 1 if state.quest_state.defeated_boss_ids.has(quest.target_id) else 0
		QuestDefinition.ObjectiveType.EXPLORE_REGION:
			return 1 if state.world_state.is_discovered(quest.target_id) else 0
	return 0


func record_battle_victory(state: GameState, boss_id: StringName) -> void:
	if state == null or state.quest_state == null or boss_id == &"":
		return
	if not state.quest_state.defeated_boss_ids.has(boss_id):
		state.quest_state.defeated_boss_ids.append(boss_id)


func record_item_used(state: GameState, item_id: StringName, amount: int) -> void:
	if state == null or state.quest_state == null or item_id == &"" or amount <= 0:
		return
	state.quest_state.used_item_counts[item_id] = state.quest_state.used_item_counts.get(item_id, 0) + amount


func _are_prerequisites_complete(state: QuestState, quest: QuestDefinition) -> bool:
	for prerequisite_id: StringName in quest.prerequisite_quest_ids:
		if not state.completed_quest_ids.has(prerequisite_id):
			return false
	return true



func _insert_by_sort_order(quests: Array[QuestDefinition], quest: QuestDefinition) -> void:
	for index: int in range(quests.size()):
		if quest.sort_order < quests[index].sort_order:
			quests.insert(index, quest)
			return
	quests.append(quest)


func _count_building(state: GameState, building_id: StringName) -> int:
	if state == null or state.raft_state == null:
		return 0
	var count: int = 0
	for instance: BuildingInstance in state.raft_state.building_instances.values():
		if instance.building_id == building_id:
			count += 1
	return count
