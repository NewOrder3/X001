class_name GameSession
extends RefCounted

## Owns the state for one new-game or loaded-game runtime lifecycle.

var _state: GameState = null
var _world_seed: int = 0
var _is_disposed: bool = false
var _data_registry: DataRegistry
var _inventory_system: InventorySystem
var _building_system: BuildingSystem
var _gathering_system: GatheringSystem
var _simulation_clock: SimulationClock
var _survival_system: SurvivalSystem
var _production_system: ProductionSystem
var _session_command_system: SessionCommandSystem
var _last_error: String = ""
var _last_offline_settlement_report: OfflineSettlementReport = null


func _init() -> void:
	_data_registry = DataRegistry.new()
	_inventory_system = InventorySystem.new(_data_registry)
	_building_system = BuildingSystem.new(_data_registry, _inventory_system)
	_gathering_system = GatheringSystem.new(_data_registry, _inventory_system)
	_simulation_clock = SimulationClock.new()
	_survival_system = SurvivalSystem.new(_data_registry, _simulation_clock)
	_production_system = ProductionSystem.new(_data_registry, _inventory_system, _simulation_clock)
	_session_command_system = SessionCommandSystem.new()


func create_new_game(world_seed: int) -> bool:
	if not _data_registry.load_all():
		_last_error = _data_registry.get_last_error()
		return false
	_world_seed = world_seed
	_state = GameState.new(world_seed)
	if not _survival_system.initialize_new_state(
		_state.survival_state,
		&"survival_default",
		int(Time.get_unix_time_from_system()),
	):
		_last_error = "Could not initialize the survival state."
		_state = null
		_is_disposed = true
		return false
	_is_disposed = false
	_last_error = ""
	_last_offline_settlement_report = null
	if not _inventory_system.add(_state.inventory_state, &"item_wood", 10):
		_last_error = "Could not grant starting resources."
		_state = null
		_is_disposed = true
		return false
	_simulation_clock.start()
	return true


func load_state(state: GameState) -> bool:
	return load_state_at(state, int(Time.get_unix_time_from_system()))


func load_state_at(state: GameState, current_unix_seconds: int) -> bool:
	assert(state != null, "GameSession.load_state requires a GameState.")
	if state == null:
		return false
	if not _data_registry.load_all():
		_last_error = _data_registry.get_last_error()
		return false

	_state = state
	_last_offline_settlement_report = _survival_system.activate_loaded_state(
		_state.survival_state,
		current_unix_seconds,
	)
	if _last_offline_settlement_report == null or not _last_offline_settlement_report.succeeded:
		_last_error = _last_offline_settlement_report.message if _last_offline_settlement_report != null else "Could not activate the survival state."
		_state = null
		_last_offline_settlement_report = null
		return false
	_world_seed = state.world_seed
	_is_disposed = false
	_last_error = ""
	_simulation_clock.start()
	return true


func dispose() -> void:
	_state = null
	_world_seed = 0
	_is_disposed = true
	_simulation_clock.pause()
	_last_offline_settlement_report = null


func has_active_state() -> bool:
	return not _is_disposed and _state != null


func get_state() -> GameState:
	assert(has_active_state(), "GameSession has no active GameState.")
	return _state


func get_world_seed() -> int:
	return _world_seed


func get_last_error() -> String:
	return _last_error


func get_last_offline_settlement_report() -> OfflineSettlementReport:
	return _last_offline_settlement_report


func execute_command(command: GameCommand) -> CommandResult:
	return _session_command_system.execute(self, command)


func get_session_events() -> SessionEvents:
	return _session_command_system.events


func get_raft_state() -> RaftState:
	if not has_active_state():
		return null
	return _state.raft_state


func get_item_amount(item_id: StringName) -> int:
	if not has_active_state():
		return 0
	return _inventory_system.get_amount(_state.inventory_state, item_id)


func get_building_definition(building_id: StringName) -> BuildingDefinition:
	if _data_registry == null or not _data_registry.has_building(building_id):
		return null
	return _data_registry.get_building(building_id)


func get_recipe_definition(recipe_id: StringName) -> RecipeDefinition:
	if _data_registry == null or not _data_registry.has_recipe(recipe_id):
		return null
	return _data_registry.get_recipe(recipe_id)


func get_building_system() -> BuildingSystem:
	return _building_system


func get_inventory_system() -> InventorySystem:
	return _inventory_system


func get_survival_state() -> SurvivalState:
	if not has_active_state():
		return null
	return _state.survival_state


func get_survival_system() -> SurvivalSystem:
	return _survival_system


func can_perform_survival_action(action_type: StringName) -> SurvivalActionResult:
	if not has_active_state():
		return SurvivalActionResult.failure(
			action_type,
			SurvivalSystem.ERROR_INVALID_SURVIVAL_STATE,
			"Start a game before performing survival actions.",
		)
	return _survival_system.can_perform_action(_state.survival_state, action_type)


func consume_survival_action_stamina(action_type: StringName) -> SurvivalActionResult:
	if not has_active_state():
		return SurvivalActionResult.failure(
			action_type,
			SurvivalSystem.ERROR_INVALID_SURVIVAL_STATE,
			"Start a game before performing survival actions.",
		)
	return _survival_system.consume_action_stamina(_state.survival_state, action_type)


func apply_survival_durability_loss(source_id: StringName, amount: float) -> SurvivalActionResult:
	if not has_active_state():
		return SurvivalActionResult.failure(
			source_id,
			SurvivalSystem.ERROR_INVALID_SURVIVAL_STATE,
			"Start a game before applying durability loss.",
		)
	return _survival_system.apply_durability_loss(_state.survival_state, source_id, amount)


func get_simulation_clock() -> SimulationClock:
	return _simulation_clock


func advance_simulation(delta_seconds: float) -> int:
	if not has_active_state():
		return 0
	var emitted_tick_count: int = _simulation_clock.advance(delta_seconds)
	_production_system.advance(_state)
	var durability_recovery: Dictionary[StringName, float] = _production_system.get_durability_recovery(_state)
	_survival_system.advance(_state.survival_state, durability_recovery[&"rate"], durability_recovery[&"accelerated_multiplier"])
	return emitted_tick_count


func execute_place_building(command: PlaceBuildingCommand) -> CommandResult:
	if not has_active_state():
		return CommandResult.failure(&"inactive_session", "Start a game before building.")
	return _building_system.execute(_state, command)


func execute_gather_resources(command: GatherResourcesCommand) -> CommandResult:
	if not has_active_state():
		return CommandResult.failure(&"inactive_session", "Start a game before gathering.")
	return _gathering_system.execute(_state, command)


func execute_use_food(command: UseFoodCommand) -> CommandResult:
	if not has_active_state() or command == null:
		return CommandResult.failure(&"inactive_session", "Start a game before using supplies.")
	if not _data_registry.has_item(command.item_id):
		return CommandResult.failure(&"unknown_item", "This item is unavailable.")
	var definition: ItemDefinition = _data_registry.get_item(command.item_id)
	if definition.supply_restore_amount <= 0.0:
		return CommandResult.failure(&"not_food", "This item cannot restore supplies.")
	var config: SurvivalConfigDefinition = _survival_system.get_config(_state.survival_state)
	if config == null or _state.survival_state.supply >= config.max_supply:
		return CommandResult.failure(&"supply_full", "Supplies are already full.")
	var cost: Dictionary[StringName, int] = {command.item_id: 1}
	if not _inventory_system.spend_cost(_state.inventory_state, cost):
		return CommandResult.failure(&"insufficient_resources", "No food is available.")
	if not _survival_system.restore_supply(_state.survival_state, definition.supply_restore_amount):
		return CommandResult.failure(&"supply_full", "Supplies are already full.")
	return CommandResult.success("Supplies restored by %.0f." % definition.supply_restore_amount)


func execute_set_production_enabled(command: SetProductionEnabledCommand) -> CommandResult:
	if not has_active_state():
		return CommandResult.failure(&"inactive_session", "Start a game before operating facilities.")
	return _production_system.set_enabled(_state, command.building_instance_id, command.is_enabled)


func get_production_system() -> ProductionSystem:
	return _production_system
