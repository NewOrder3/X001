class_name ProgressionSystem
extends RefCounted

## Owns raft growth and data-driven unlock rules. Other systems query unlocks here
## instead of inspecting State containers directly.

signal raft_upgraded(new_level: int)

const UNLOCK_EXPLORATION: StringName = &"unlock_exploration"
const ERROR_INVALID_PROGRESSION_STATE: StringName = &"invalid_progression_state"
const ERROR_MAX_RAFT_LEVEL: StringName = &"max_raft_level"
const ERROR_INSUFFICIENT_RESOURCES: StringName = &"insufficient_resources"

var _data_registry: DataRegistry
var _inventory_system: InventorySystem


func _init(new_data_registry: DataRegistry, new_inventory_system: InventorySystem) -> void:
	_data_registry = new_data_registry
	_inventory_system = new_inventory_system


func initialize_new_state(state: ProgressionState) -> bool:
	if state == null or _data_registry == null or _data_registry.get_raft_level_progression(1) == null:
		return false
	state.raft_level = 1
	return true


func activate_loaded_state(state: GameState) -> bool:
	if state == null or state.progression_state == null or state.raft_state == null or _data_registry == null:
		return false
	var definition: ProgressionDefinition = _data_registry.get_raft_level_progression(state.progression_state.raft_level)
	if definition == null:
		return false
	state.raft_state.grid.expand_deck_to(definition.raft_width, definition.raft_height)
	return true


func get_current_raft_definition(state: ProgressionState) -> ProgressionDefinition:
	if state == null or _data_registry == null:
		return null
	return _data_registry.get_raft_level_progression(state.raft_level)


func get_raft_upgrade_definition(state: ProgressionState) -> ProgressionDefinition:
	var current: ProgressionDefinition = get_current_raft_definition(state)
	if current == null:
		return null
	return _data_registry.get_raft_level_progression(current.raft_level + 1)


func get_raft_upgrade_cost(state: ProgressionState) -> Dictionary[StringName, int]:
	var current: ProgressionDefinition = get_current_raft_definition(state)
	if current == null:
		return {}
	return current.upgrade_cost.duplicate()


func upgrade_raft(state: GameState) -> CommandResult:
	if state == null or state.progression_state == null or state.raft_state == null:
		return CommandResult.failure(
			ERROR_INVALID_PROGRESSION_STATE,
			GameText.get_text(&"message.progression.raft_unavailable"),
		)
	var next: ProgressionDefinition = get_raft_upgrade_definition(state.progression_state)
	if next == null:
		return CommandResult.failure(ERROR_MAX_RAFT_LEVEL, GameText.get_text(&"message.progression.max_level"))
	var current: ProgressionDefinition = get_current_raft_definition(state.progression_state)
	if current == null:
		return CommandResult.failure(
			ERROR_INVALID_PROGRESSION_STATE,
			GameText.get_text(&"message.progression.raft_unavailable"),
		)
	if _inventory_system == null or not _inventory_system.can_afford(state.inventory_state, current.upgrade_cost):
		return CommandResult.failure(
			ERROR_INSUFFICIENT_RESOURCES,
			GameText.get_text(&"message.progression.insufficient_resources"),
		)
	if not _inventory_system.spend_cost(state.inventory_state, current.upgrade_cost):
		return CommandResult.failure(
			ERROR_INSUFFICIENT_RESOURCES,
			GameText.get_text(&"message.progression.insufficient_resources"),
		)
	if not state.raft_state.grid.expand_deck_to(next.raft_width, next.raft_height):
		_refund(state, current.upgrade_cost)
		return CommandResult.failure(
			ERROR_INVALID_PROGRESSION_STATE,
			GameText.get_text(&"message.progression.raft_unavailable"),
		)
	state.progression_state.raft_level = next.raft_level
	raft_upgraded.emit(next.raft_level)
	return CommandResult.success(
		GameText.format(&"message.progression.raft_upgraded", [next.raft_level, next.raft_width, next.raft_height])
	)


func is_unlock_available(state: GameState, unlock_id: StringName) -> bool:
	if state == null or _data_registry == null:
		return false
	var definition: ProgressionDefinition = _data_registry.get_unlock_progression(unlock_id)
	if definition == null:
		return false
	if definition.required_raft_level > 0 and (
		state.progression_state == null or state.progression_state.raft_level < definition.required_raft_level
	):
		return false
	if definition.required_building_id != &"":
		if state.raft_state == null:
			return false
		var has_required_building: bool = false
		for instance: BuildingInstance in state.raft_state.building_instances.values():
			if instance.building_id == definition.required_building_id:
				has_required_building = true
				break
		if not has_required_building:
			return false
	return true


func _refund(state: GameState, cost: Dictionary[StringName, int]) -> void:
	for item_id: StringName in cost:
		var capacity: int = _inventory_system.get_capacity(state, item_id)
		_inventory_system.add(state.inventory_state, item_id, cost[item_id], capacity)
