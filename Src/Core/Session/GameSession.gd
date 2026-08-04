class_name GameSession
extends RefCounted

## Owns the state for one new-game or loaded-game runtime lifecycle.

var _state: GameState = null
var _world_seed: int = 0
var _is_disposed: bool = false
var _data_registry: DataRegistry
var _inventory_system: InventorySystem
var _building_system: BuildingSystem
var _simulation_clock: SimulationClock
var _survival_system: SurvivalSystem
var _last_error: String = ""


func _init() -> void:
	_data_registry = DataRegistry.new()
	_inventory_system = InventorySystem.new(_data_registry)
	_building_system = BuildingSystem.new(_data_registry, _inventory_system)
	_simulation_clock = SimulationClock.new()
	_survival_system = SurvivalSystem.new(_data_registry, _simulation_clock)


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
	if not _inventory_system.add(_state.inventory_state, &"item_wood", 10):
		_last_error = "Could not grant starting resources."
		_state = null
		_is_disposed = true
		return false
	_simulation_clock.start()
	return true


func load_state(state: GameState) -> bool:
	assert(state != null, "GameSession.load_state requires a GameState.")
	if state == null:
		return false
	if not _data_registry.load_all():
		_last_error = _data_registry.get_last_error()
		return false

	_state = state
	if not _survival_system.activate_loaded_state(_state.survival_state, int(Time.get_unix_time_from_system())):
		_last_error = "Could not activate the survival state."
		_state = null
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


func has_active_state() -> bool:
	return not _is_disposed and _state != null


func get_state() -> GameState:
	assert(has_active_state(), "GameSession has no active GameState.")
	return _state


func get_world_seed() -> int:
	return _world_seed


func get_last_error() -> String:
	return _last_error


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


func get_building_system() -> BuildingSystem:
	return _building_system


func get_survival_state() -> SurvivalState:
	if not has_active_state():
		return null
	return _state.survival_state


func get_survival_system() -> SurvivalSystem:
	return _survival_system


func get_simulation_clock() -> SimulationClock:
	return _simulation_clock


func advance_simulation(delta_seconds: float) -> int:
	if not has_active_state():
		return 0
	var emitted_tick_count: int = _simulation_clock.advance(delta_seconds)
	_survival_system.advance(_state.survival_state)
	return emitted_tick_count


func execute_place_building(command: PlaceBuildingCommand) -> CommandResult:
	if not has_active_state():
		return CommandResult.failure(&"inactive_session", "Start a game before building.")
	return _building_system.execute(_state, command)
