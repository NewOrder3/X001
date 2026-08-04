class_name ProductionSystem
extends RefCounted

## Advances facility recipes in batches on simulation time; it never depends on Views.

signal production_changed(building_instance_id: StringName)
signal production_stalled(building_instance_id: StringName, reason: ProductionInstance.StallReason)

var _data_registry: DataRegistry
var _inventory_system: InventorySystem
var _clock: SimulationClock
var _accumulated_seconds: float = 0.0


func _init(data_registry: DataRegistry, inventory_system: InventorySystem, clock: SimulationClock) -> void:
	_data_registry = data_registry
	_inventory_system = inventory_system
	_clock = clock
	if _clock != null:
		_clock.simulation_tick.connect(_on_simulation_tick)


func advance(state: GameState) -> int:
	if state == null or _accumulated_seconds <= 0.0:
		return 0
	_sync_instances(state)
	var elapsed_seconds: float = _accumulated_seconds
	_accumulated_seconds = 0.0
	var completed_cycles: int = 0
	for production: ProductionInstance in state.production_state.instances.values():
		completed_cycles += _advance_instance(state, production, elapsed_seconds)
	return completed_cycles


func set_enabled(state: GameState, building_instance_id: StringName, is_enabled: bool) -> CommandResult:
	if state == null or building_instance_id == &"":
		return CommandResult.failure(&"invalid_production_target", "Choose a valid facility.")
	_sync_instances(state)
	if not state.production_state.instances.has(building_instance_id):
		return CommandResult.failure(&"not_a_production_facility", "This building cannot be operated.")
	var production: ProductionInstance = state.production_state.instances[building_instance_id]
	production.is_enabled = is_enabled
	production.stall_reason = ProductionInstance.StallReason.NONE if is_enabled else ProductionInstance.StallReason.MANUALLY_STOPPED
	production_changed.emit(building_instance_id)
	return CommandResult.success("Facility %s." % ("started" if is_enabled else "stopped"))


func get_instance(state: GameState, building_instance_id: StringName) -> ProductionInstance:
	if state == null:
		return null
	_sync_instances(state)
	return state.production_state.instances.get(building_instance_id) as ProductionInstance


func get_durability_recovery(state: GameState) -> Dictionary[StringName, float]:
	_sync_instances(state)
	var recovery_rate: float = 0.0
	var accelerated_multiplier: float = 1.0
	if state == null or state.survival_state.supply <= 0.0:
		return {&"rate": recovery_rate, &"accelerated_multiplier": accelerated_multiplier}
	for building: BuildingInstance in state.raft_state.building_instances.values():
		var definition: BuildingDefinition = _data_registry.get_building(building.building_id) if _data_registry != null and _data_registry.has_building(building.building_id) else null
		var production: ProductionInstance = get_instance(state, building.instance_id)
		if definition != null and production != null and production.is_enabled and definition.durability_recovery_per_minute > 0.0:
			recovery_rate += definition.durability_recovery_per_minute
			accelerated_multiplier = maxf(accelerated_multiplier, definition.durability_recovery_accelerated_multiplier)
	return {&"rate": recovery_rate, &"accelerated_multiplier": accelerated_multiplier}


func _on_simulation_tick(delta_seconds: float) -> void:
	_accumulated_seconds += delta_seconds


func _sync_instances(state: GameState) -> void:
	if state == null or _data_registry == null:
		return
	var current_buildings: Dictionary[StringName, bool] = {}
	for building: BuildingInstance in state.raft_state.building_instances.values():
		current_buildings[building.instance_id] = true
		var definition: BuildingDefinition = _data_registry.get_building(building.building_id) if _data_registry.has_building(building.building_id) else null
		if definition == null or (definition.recipe_id == &"" and definition.durability_recovery_per_minute <= 0.0):
			continue
		if not state.production_state.instances.has(building.instance_id):
			state.production_state.instances[building.instance_id] = ProductionInstance.new(building.instance_id, definition.recipe_id)
	for instance_id: StringName in state.production_state.instances.keys():
		if not current_buildings.has(instance_id):
			state.production_state.instances.erase(instance_id)


func _advance_instance(state: GameState, production: ProductionInstance, elapsed_seconds: float) -> int:
	var previous_reason: ProductionInstance.StallReason = production.stall_reason
	if not production.is_enabled:
		production.stall_reason = ProductionInstance.StallReason.MANUALLY_STOPPED
		_notify_if_changed(production, previous_reason)
		return 0
	if state.survival_state.supply <= 0.0:
		production.stall_reason = ProductionInstance.StallReason.SUPPLY_DEPLETED
		_notify_if_changed(production, previous_reason)
		return 0
	if production.recipe_id == &"":
		production.stall_reason = ProductionInstance.StallReason.NONE
		_notify_if_changed(production, previous_reason)
		return 0
	var recipe: RecipeDefinition = _data_registry.get_recipe(production.recipe_id) if _data_registry != null and _data_registry.has_recipe(production.recipe_id) else null
	if recipe == null:
		return 0
	if not _inventory_system.can_afford(state.inventory_state, recipe.input_items):
		production.stall_reason = ProductionInstance.StallReason.MISSING_INPUT
		_notify_if_changed(production, previous_reason)
		return 0
	if not _can_store_outputs(state, recipe.output_items):
		production.stall_reason = ProductionInstance.StallReason.OUTPUT_CAPACITY_REACHED
		_notify_if_changed(production, previous_reason)
		return 0
	production.stall_reason = ProductionInstance.StallReason.NONE
	production.progress_seconds += elapsed_seconds
	var completed_cycles: int = int(floor(production.progress_seconds / recipe.cycle_seconds))
	if completed_cycles <= 0:
		production_changed.emit(production.building_instance_id)
		_notify_if_changed(production, previous_reason)
		return 0
	var affordable_cycles: int = _get_affordable_cycle_count(state.inventory_state, recipe.input_items)
	var capacity_cycles: int = _get_capacity_cycle_count(state, recipe.output_items)
	var final_cycles: int = mini(completed_cycles, mini(affordable_cycles, capacity_cycles))
	if final_cycles <= 0:
		production.stall_reason = ProductionInstance.StallReason.MISSING_INPUT if affordable_cycles == 0 else ProductionInstance.StallReason.OUTPUT_CAPACITY_REACHED
		_notify_if_changed(production, previous_reason)
		return 0
	var total_inputs: Dictionary[StringName, int] = _multiply_items(recipe.input_items, final_cycles)
	var total_outputs: Dictionary[StringName, int] = _multiply_items(recipe.output_items, final_cycles)
	if not _inventory_system.spend_cost(state.inventory_state, total_inputs):
		return 0
	for item_id: StringName in total_outputs:
		_inventory_system.add(state.inventory_state, item_id, total_outputs[item_id], _inventory_system.get_capacity(state, item_id))
	production.progress_seconds -= recipe.cycle_seconds * float(final_cycles)
	production_changed.emit(production.building_instance_id)
	return final_cycles


func _can_store_outputs(state: GameState, outputs: Dictionary[StringName, int]) -> bool:
	for item_id: StringName in outputs:
		if not _inventory_system.can_add(state.inventory_state, item_id, outputs[item_id], _inventory_system.get_capacity(state, item_id)):
			return false
	return true


func _get_affordable_cycle_count(inventory: InventoryState, costs: Dictionary[StringName, int]) -> int:
	var result: int = 999999
	if costs.is_empty():
		return result
	for item_id: StringName in costs:
		result = mini(result, _inventory_system.get_amount(inventory, item_id) / costs[item_id])
	return result


func _get_capacity_cycle_count(state: GameState, outputs: Dictionary[StringName, int]) -> int:
	var result: int = 999999
	for item_id: StringName in outputs:
		var remaining: int = _inventory_system.get_capacity(state, item_id) - _inventory_system.get_amount(state.inventory_state, item_id)
		result = mini(result, remaining / outputs[item_id])
	return result


func _multiply_items(items: Dictionary[StringName, int], multiplier: int) -> Dictionary[StringName, int]:
	var multiplied: Dictionary[StringName, int] = {}
	for item_id: StringName in items:
		multiplied[item_id] = items[item_id] * multiplier
	return multiplied


func _notify_if_changed(production: ProductionInstance, previous_reason: ProductionInstance.StallReason) -> void:
	if production.stall_reason != previous_reason:
		production_stalled.emit(production.building_instance_id, production.stall_reason)
		production_changed.emit(production.building_instance_id)
