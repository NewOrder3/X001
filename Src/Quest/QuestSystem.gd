class_name QuestSystem
extends RefCounted

## Derives new-player goal progress from public GameState fields and persists only
## completion markers plus defeated bosses. It never owns inventory or building rules.

var _data_registry: DataRegistry


func _init(new_data_registry: DataRegistry) -> void:
	_data_registry = new_data_registry


func initialize_new_state(state: QuestState) -> bool:
	if state == null:
		return false
	state.completed_quest_ids.clear()
	state.defeated_boss_ids.clear()
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
	return true


func get_active_quests(state: GameState) -> Array[QuestDefinition]:
	var quests: Array[QuestDefinition] = []
	if state == null or state.quest_state == null or _data_registry == null:
		return quests
	for quest: QuestDefinition in _data_registry.get_quests():
		if not state.quest_state.completed_quest_ids.has(quest.id) and not is_completed(state, quest.id):
			quests.append(quest)
	return quests


func is_completed(state: GameState, quest_id: StringName) -> bool:
	if state == null or state.quest_state == null or _data_registry == null or not _data_registry.has_quest(quest_id):
		return false
	if state.quest_state.completed_quest_ids.has(quest_id):
		return true
	var quest: QuestDefinition = _data_registry.get_quest(quest_id)
	if get_progress(state, quest_id) >= quest.target_amount:
		state.quest_state.completed_quest_ids.append(quest_id)
		return true
	return false


func get_progress(state: GameState, quest_id: StringName) -> int:
	if state == null or _data_registry == null or not _data_registry.has_quest(quest_id):
		return 0
	var quest: QuestDefinition = _data_registry.get_quest(quest_id)
	match quest.objective_type:
		QuestDefinition.ObjectiveType.BUILD_BUILDING:
			return _count_building(state, quest.target_id)
		QuestDefinition.ObjectiveType.HAVE_ITEM:
			return state.inventory_state.item_amounts.get(quest.target_id, 0)
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


func _count_building(state: GameState, building_id: StringName) -> int:
	if state == null or state.raft_state == null:
		return 0
	var count: int = 0
	for instance: BuildingInstance in state.raft_state.building_instances.values():
		if instance.building_id == building_id:
			count += 1
	return count
