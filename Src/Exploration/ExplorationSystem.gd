class_name ExplorationSystem
extends RefCounted

## Owns map travel validation, deterministic encounter resolution, and world-state mutations.

signal exploration_completed(result: ExplorationResult)

const EXPLORATION_STREAM_PREFIX: String = "exploration_"
const ERROR_INVALID_WORLD_STATE: StringName = &"invalid_world_state"
const ERROR_UNKNOWN_REGION: StringName = &"unknown_region"
const ERROR_NOT_ADJACENT: StringName = &"not_adjacent"
const ERROR_INVENTORY_FULL: StringName = &"inventory_full"
const ERROR_EXPLORATION_LOCKED: StringName = &"exploration_locked"
const REQUIRED_BUILDING_ID: StringName = &"building_rudder"

var _data_registry: DataRegistry
var _inventory_system: InventorySystem
var _survival_system: SurvivalSystem
var _random_service: RandomService


func _init(
	new_data_registry: DataRegistry,
	new_inventory_system: InventorySystem,
	new_survival_system: SurvivalSystem,
	new_random_service: RandomService,
) -> void:
	_data_registry = new_data_registry
	_inventory_system = new_inventory_system
	_survival_system = new_survival_system
	_random_service = new_random_service


func initialize_new_state(state: WorldState) -> bool:
	if state == null or _data_registry == null:
		return false
	var starting_region: RegionDefinition = _data_registry.get_starting_region()
	if starting_region == null:
		return false
	state.initialize(starting_region.id)
	return true


func activate_loaded_state(state: WorldState) -> bool:
	if state == null or _data_registry == null:
		return false
	if state.current_region_id == &"":
		return initialize_new_state(state)
	if not _data_registry.has_region(state.current_region_id):
		return false
	for region_id: StringName in state.discovered_region_ids:
		if not _data_registry.has_region(region_id):
			return false
	if not state.is_discovered(state.current_region_id):
		state.mark_discovered(state.current_region_id)
	return true


func get_reachable_regions(state: WorldState) -> Array[RegionDefinition]:
	var regions: Array[RegionDefinition] = []
	if state == null or _data_registry == null or not _data_registry.has_region(state.current_region_id):
		return regions
	var current: RegionDefinition = _data_registry.get_region(state.current_region_id)
	for region: RegionDefinition in _data_registry.get_regions():
		if region.id != current.id and HexGrid.distance_to_coord(current.coordinate, region.coordinate) == 1:
			regions.append(region)
	return regions


func is_unlocked(state: GameState) -> bool:
	return _has_required_rudder(state)


func execute(state: GameState, command: ExploreRegionCommand) -> ExplorationResult:
	if state == null or command == null or state.world_state == null:
		return ExplorationResult.failure(ERROR_INVALID_WORLD_STATE, GameText.get_text(&"message.exploration.no_world_state"))
	if _data_registry == null or not _data_registry.has_region(command.target_region_id):
		return ExplorationResult.failure(ERROR_UNKNOWN_REGION, GameText.get_text(&"message.exploration.region_unavailable"))
	if not _has_required_rudder(state):
		return ExplorationResult.failure(ERROR_EXPLORATION_LOCKED, GameText.get_text(&"message.exploration.rudder_required"))
	if not _data_registry.has_region(state.world_state.current_region_id):
		return ExplorationResult.failure(ERROR_INVALID_WORLD_STATE, GameText.get_text(&"message.exploration.current_region_unavailable"))

	var origin: RegionDefinition = _data_registry.get_region(state.world_state.current_region_id)
	var target: RegionDefinition = _data_registry.get_region(command.target_region_id)
	if HexGrid.distance_to_coord(origin.coordinate, target.coordinate) != 1:
		return ExplorationResult.failure(ERROR_NOT_ADJACENT, GameText.get_text(&"message.exploration.not_adjacent"))

	var action_check: SurvivalActionResult = _survival_system.can_perform_action(
		state.survival_state,
		SurvivalSystem.ACTION_EXPLORE,
	)
	if not action_check.succeeded:
		return ExplorationResult.failure(action_check.error_code, action_check.message)

	var encounter: EncounterDefinition = _resolve_encounter(state.world_state, target)
	if encounter != null and not _can_receive_rewards(state, encounter.reward_items):
		return ExplorationResult.failure(ERROR_INVENTORY_FULL, GameText.get_text(&"message.exploration.reward_inventory_full"))

	# All fallible validation is complete before the action resource is consumed.
	var consume_result: SurvivalActionResult = _survival_system.consume_action_stamina(
		state.survival_state,
		SurvivalSystem.ACTION_EXPLORE,
	)
	if not consume_result.succeeded:
		return ExplorationResult.failure(consume_result.error_code, consume_result.message)

	state.world_state.current_region_id = target.id
	state.world_state.mark_discovered(target.id)
	state.world_state.exploration_revision += 1

	var reward_items: Dictionary[StringName, int] = {}
	var durability_loss: float = 0.0
	var encounter_id: StringName = &""
	var message: String = GameText.format(&"message.exploration.arrived_calm", [target.get_display_name()])
	if encounter != null:
		encounter_id = encounter.id
		state.world_state.mark_encounter_consumed(_get_consumed_key(target.id, encounter.id))
		for item_id: StringName in encounter.reward_items:
			var amount: int = encounter.reward_items[item_id]
			var capacity: int = _inventory_system.get_capacity(state, item_id)
			_inventory_system.add(state.inventory_state, item_id, amount, capacity)
			reward_items[item_id] = amount
		if encounter.durability_loss > 0.0:
			var durability_result: SurvivalActionResult = _survival_system.apply_durability_loss(
				state.survival_state,
				encounter.id,
				encounter.durability_loss,
			)
			durability_loss = durability_result.durability_loss if durability_result.succeeded else 0.0
		message = _get_encounter_message(target, encounter, reward_items, durability_loss)

	var result: ExplorationResult = ExplorationResult.new(
		true,
		&"",
		message,
		origin.id,
		target.id,
		encounter_id,
		reward_items,
		durability_loss,
		consume_result.stamina_cost,
	)
	exploration_completed.emit(result)
	return result


func _resolve_encounter(state: WorldState, region: RegionDefinition) -> EncounterDefinition:
	var available_encounters: Array[StringName] = []
	for encounter_id: StringName in region.encounter_ids:
		if not state.is_encounter_consumed(_get_consumed_key(region.id, encounter_id)):
			available_encounters.append(encounter_id)
	if available_encounters.is_empty():
		return null
	var stream_id: StringName = StringName("%s%s" % [EXPLORATION_STREAM_PREFIX, String(region.id)])
	var selected_index: int = _random_service.range_i_from_stream(stream_id, 0, available_encounters.size() - 1)
	return _data_registry.get_encounter(available_encounters[selected_index])


func _can_receive_rewards(state: GameState, rewards: Dictionary[StringName, int]) -> bool:
	for item_id: StringName in rewards:
		var capacity: int = _inventory_system.get_capacity(state, item_id)
		if not _inventory_system.can_add(state.inventory_state, item_id, rewards[item_id], capacity):
			return false
	return true


func _has_required_rudder(state: GameState) -> bool:
	if state == null or state.raft_state == null:
		return false
	for building: BuildingInstance in state.raft_state.building_instances.values():
		if building.building_id == REQUIRED_BUILDING_ID:
			return true
	return false


func _get_consumed_key(region_id: StringName, encounter_id: StringName) -> StringName:
	return StringName("%s:%s" % [String(region_id), String(encounter_id)])


func _get_encounter_message(
	region: RegionDefinition,
	encounter: EncounterDefinition,
	rewards: Dictionary[StringName, int],
	durability_loss: float,
) -> String:
	match encounter.outcome_type:
		EncounterDefinition.OutcomeType.RESOURCE:
			return GameText.format(&"message.exploration.arrived_rewards", [region.get_display_name(), _format_rewards(rewards)])
		EncounterDefinition.OutcomeType.STORM:
			return GameText.format(&"message.exploration.arrived_storm", [region.get_display_name(), durability_loss])
	return GameText.format(&"message.exploration.arrived_encounter", [region.get_display_name(), encounter.get_description()])


func _format_rewards(rewards: Dictionary[StringName, int]) -> String:
	var parts: PackedStringArray = []
	for item_id: StringName in rewards:
		var item: ItemDefinition = _data_registry.get_item(item_id)
		parts.append(GameText.format(&"message.exploration.reward_entry", [item.get_display_name(), rewards[item_id]]))
	return GameText.format(&"message.exploration.found_rewards", ["、".join(parts)])
