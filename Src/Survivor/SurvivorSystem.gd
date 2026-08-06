class_name SurvivorSystem
extends RefCounted

## Owns recruitment, levelling, lineup validation, and passive-card queries.

signal recruitment_offered(survivor_id: StringName)
signal survivor_recruited(survivor_id: StringName)
signal survivor_upgraded(survivor_id: StringName, level: int)
signal lineup_changed(lineup_ids: Array[StringName])
signal survivor_experience_gained(survivor_id: StringName, total_experience: int)

const MIN_LEVEL: int = 1
const MAX_LEVEL: int = 10
const ERROR_INVALID_STATE: StringName = &"invalid_survivor_state"
const ERROR_UNKNOWN_SURVIVOR: StringName = &"unknown_survivor"
const ERROR_NOT_RESCUED: StringName = &"not_rescued"
const ERROR_ALREADY_RECRUITED: StringName = &"already_recruited"
const ERROR_NOT_RECRUITED: StringName = &"not_recruited"
const ERROR_MAX_LEVEL: StringName = &"max_level"
const ERROR_INSUFFICIENT_RESOURCES: StringName = &"insufficient_resources"
const ERROR_INVALID_LINEUP: StringName = &"invalid_lineup"

var _data_registry: DataRegistry
var _inventory_system: InventorySystem


func _init(new_data_registry: DataRegistry, new_inventory_system: InventorySystem) -> void:
	_data_registry = new_data_registry
	_inventory_system = new_inventory_system


func offer_recruitment(state: SurvivorState, survivor_id: StringName) -> bool:
	if state == null or _data_registry == null or not _data_registry.has_survivor(survivor_id):
		return false
	if state.survivors.has(survivor_id) or state.pending_recruitment_ids.has(survivor_id):
		return false
	state.pending_recruitment_ids.append(survivor_id)
	recruitment_offered.emit(survivor_id)
	return true


func activate_loaded_state(state: SurvivorState) -> bool:
	if state == null or _data_registry == null or state.lineup_ids.size() > SurvivorState.MAX_LINEUP_SIZE:
		return false
	for survivor_id: StringName in state.survivors:
		if not _data_registry.has_survivor(survivor_id):
			return false
		var instance: SurvivorInstance = state.survivors[survivor_id]
		if instance == null or instance.survivor_id != survivor_id or instance.level < MIN_LEVEL or instance.level > MAX_LEVEL:
			return false
	for survivor_id: StringName in state.pending_recruitment_ids:
		if not _data_registry.has_survivor(survivor_id) or state.survivors.has(survivor_id):
			return false
	var unique_lineup_ids: Dictionary[StringName, bool] = {}
	for survivor_id: StringName in state.lineup_ids:
		if not state.survivors.has(survivor_id) or unique_lineup_ids.has(survivor_id):
			return false
		unique_lineup_ids[survivor_id] = true
	return true


func recruit(state: GameState, survivor_id: StringName) -> CommandResult:
	if state == null or state.survivor_state == null:
		return CommandResult.failure(ERROR_INVALID_STATE, GameText.get_text(&"message.survivor.state_unavailable"))
	if _data_registry == null or not _data_registry.has_survivor(survivor_id):
		return CommandResult.failure(ERROR_UNKNOWN_SURVIVOR, GameText.get_text(&"message.survivor.unavailable"))
	if state.survivor_state.survivors.has(survivor_id):
		return CommandResult.failure(ERROR_ALREADY_RECRUITED, GameText.get_text(&"message.survivor.already_recruited"))
	if not state.survivor_state.pending_recruitment_ids.has(survivor_id):
		return CommandResult.failure(ERROR_NOT_RESCUED, GameText.get_text(&"message.survivor.not_rescued"))

	state.survivor_state.pending_recruitment_ids.erase(survivor_id)
	state.survivor_state.survivors[survivor_id] = SurvivorInstance.new(survivor_id, survivor_id, MIN_LEVEL)
	survivor_recruited.emit(survivor_id)
	return CommandResult.success(GameText.format(&"message.survivor.recruited", [_data_registry.get_survivor(survivor_id).get_display_name()]))


func upgrade(state: GameState, survivor_id: StringName) -> CommandResult:
	if state == null or state.survivor_state == null or state.inventory_state == null:
		return CommandResult.failure(ERROR_INVALID_STATE, GameText.get_text(&"message.survivor.state_unavailable"))
	if not state.survivor_state.survivors.has(survivor_id):
		return CommandResult.failure(ERROR_NOT_RECRUITED, GameText.get_text(&"message.survivor.not_recruited"))
	if _data_registry == null or not _data_registry.has_survivor(survivor_id):
		return CommandResult.failure(ERROR_UNKNOWN_SURVIVOR, GameText.get_text(&"message.survivor.unavailable"))
	var instance: SurvivorInstance = state.survivor_state.survivors[survivor_id]
	if instance.level >= MAX_LEVEL:
		return CommandResult.failure(ERROR_MAX_LEVEL, GameText.get_text(&"message.survivor.max_level"))
	var definition: SurvivorDefinition = _data_registry.get_survivor(survivor_id)
	if not _inventory_system.spend_cost(state.inventory_state, definition.upgrade_cost):
		return CommandResult.failure(ERROR_INSUFFICIENT_RESOURCES, GameText.get_text(&"message.survivor.insufficient_resources"))
	instance.level += 1
	survivor_upgraded.emit(survivor_id, instance.level)
	return CommandResult.success(GameText.format(&"message.survivor.upgraded", [definition.get_display_name(), instance.level]))


func set_lineup(state: SurvivorState, lineup_ids: Array[StringName]) -> CommandResult:
	if state == null:
		return CommandResult.failure(ERROR_INVALID_STATE, GameText.get_text(&"message.survivor.state_unavailable"))
	if lineup_ids.size() > SurvivorState.MAX_LINEUP_SIZE:
		return CommandResult.failure(ERROR_INVALID_LINEUP, GameText.get_text(&"message.survivor.lineup_full"))
	var unique_ids: Dictionary[StringName, bool] = {}
	for survivor_id: StringName in lineup_ids:
		if survivor_id == &"" or unique_ids.has(survivor_id) or not state.survivors.has(survivor_id):
			return CommandResult.failure(ERROR_INVALID_LINEUP, GameText.get_text(&"message.survivor.invalid_lineup"))
		unique_ids[survivor_id] = true
	state.lineup_ids = lineup_ids.duplicate()
	lineup_changed.emit(state.lineup_ids.duplicate())
	return CommandResult.success(GameText.get_text(&"message.survivor.lineup_updated"))


func get_owned_survivors(state: SurvivorState) -> Array[SurvivorInstance]:
	var instances: Array[SurvivorInstance] = []
	if state == null:
		return instances
	var survivor_ids: Array[StringName] = []
	for survivor_id: StringName in state.survivors:
		survivor_ids.append(survivor_id)
	survivor_ids.sort()
	for survivor_id: StringName in survivor_ids:
		instances.append(state.survivors[survivor_id])
	return instances


func get_lineup_passive_value(state: SurvivorState, passive_id: StringName) -> float:
	if state == null or _data_registry == null or passive_id == &"":
		return 0.0
	var total: float = 0.0
	for survivor_id: StringName in state.lineup_ids:
		if not state.survivors.has(survivor_id) or not _data_registry.has_survivor(survivor_id):
			continue
		var definition: SurvivorDefinition = _data_registry.get_survivor(survivor_id)
		if definition.passive_id == passive_id:
			var instance: SurvivorInstance = state.survivors[survivor_id]
			total += definition.passive_value_per_level * float(instance.level)
	return total


func grant_lineup_experience(state: SurvivorState, amount: int) -> bool:
	if state == null or amount <= 0 or state.lineup_ids.is_empty():
		return false
	for survivor_id: StringName in state.lineup_ids:
		if not state.survivors.has(survivor_id):
			return false
	for survivor_id: StringName in state.lineup_ids:
		var instance: SurvivorInstance = state.survivors[survivor_id]
		instance.experience += amount
		survivor_experience_gained.emit(survivor_id, instance.experience)
	return true
