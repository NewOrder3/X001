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
var _survivor_system: SurvivorSystem
var _random_service: RandomService
var _exploration_system: ExplorationSystem
var _battle_system: BattleSystem
var _session_command_system: SessionCommandSystem
var _last_error: String = ""
var _last_offline_settlement_report: OfflineSettlementReport = null
var _last_exploration_result: ExplorationResult = null
var _last_battle_action_result: BattleActionResult = null


func _init() -> void:
	_data_registry = DataRegistry.new()
	_inventory_system = InventorySystem.new(_data_registry)
	_building_system = BuildingSystem.new(_data_registry, _inventory_system)
	_gathering_system = GatheringSystem.new(_data_registry, _inventory_system)
	_simulation_clock = SimulationClock.new()
	_survival_system = SurvivalSystem.new(_data_registry, _simulation_clock)
	_production_system = ProductionSystem.new(_data_registry, _inventory_system, _simulation_clock)
	_survivor_system = SurvivorSystem.new(_data_registry, _inventory_system)
	_random_service = RandomService.new()
	_exploration_system = ExplorationSystem.new(_data_registry, _inventory_system, _survival_system, _survivor_system, _random_service)
	_battle_system = BattleSystem.new(_data_registry, _random_service)
	_session_command_system = SessionCommandSystem.new()


func create_new_game(world_seed: int) -> bool:
	if not _data_registry.load_all():
		_last_error = _data_registry.get_last_error()
		return false
	_world_seed = world_seed
	_random_service.set_world_seed(world_seed)
	_state = GameState.new(world_seed)
	if not _survival_system.initialize_new_state(
		_state.survival_state,
		&"survival_default",
		int(Time.get_unix_time_from_system()),
	):
		_last_error = GameText.get_text(&"message.survival.state_unavailable")
		_state = null
		_is_disposed = true
		return false
	if not _exploration_system.initialize_new_state(_state.world_state):
		_last_error = GameText.get_text(&"message.exploration.no_world_state")
		_state = null
		_is_disposed = true
		return false
	_is_disposed = false
	_last_error = ""
	_last_offline_settlement_report = null
	_last_exploration_result = null
	_last_battle_action_result = null
	if not _inventory_system.add(_state.inventory_state, &"item_wood", 10):
		_last_error = GameText.get_text(&"message.gather.unavailable")
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
	if not _survivor_system.activate_loaded_state(_state.survivor_state):
		_last_error = GameText.get_text(&"message.survivor.state_unavailable")
		_state = null
		return false
	_last_offline_settlement_report = _survival_system.activate_loaded_state(
		_state.survival_state,
		current_unix_seconds,
	)
	if _last_offline_settlement_report == null or not _last_offline_settlement_report.succeeded:
		_last_error = _last_offline_settlement_report.message if _last_offline_settlement_report != null else GameText.get_text(&"message.survival.state_unavailable")
		_state = null
		_last_offline_settlement_report = null
		return false
	_world_seed = state.world_seed
	_random_service.set_world_seed(_world_seed)
	if not _exploration_system.activate_loaded_state(_state.world_state):
		_last_error = GameText.get_text(&"message.exploration.no_world_state")
		_state = null
		return false
	if not _battle_system.validate_loaded_state(_state):
		_last_error = GameText.get_text(&"message.battle.state_unavailable")
		_state = null
		return false
	_is_disposed = false
	_last_error = ""
	_simulation_clock.start()
	return true


func dispose() -> void:
	_state = null
	_world_seed = 0
	_random_service.set_world_seed(0)
	_is_disposed = true
	_simulation_clock.pause()
	_last_offline_settlement_report = null
	_last_exploration_result = null
	_last_battle_action_result = null


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


func get_last_exploration_result() -> ExplorationResult:
	return _last_exploration_result


func get_last_battle_action_result() -> BattleActionResult:
	return _last_battle_action_result


func execute_command(command: GameCommand) -> CommandResult:
	return _session_command_system.execute(self, command)


func get_session_events() -> SessionEvents:
	return _session_command_system.events


func get_raft_state() -> RaftState:
	if not has_active_state():
		return null
	return _state.raft_state


func get_world_state() -> WorldState:
	if not has_active_state():
		return null
	return _state.world_state


func get_item_amount(item_id: StringName) -> int:
	if not has_active_state():
		return 0
	return _inventory_system.get_amount(_state.inventory_state, item_id)


func get_building_definition(building_id: StringName) -> BuildingDefinition:
	if _data_registry == null or not _data_registry.has_building(building_id):
		return null
	return _data_registry.get_building(building_id)


func get_item_definition(item_id: StringName) -> ItemDefinition:
	if _data_registry == null or not _data_registry.has_item(item_id):
		return null
	return _data_registry.get_item(item_id)


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


func get_survivor_state() -> SurvivorState:
	if not has_active_state():
		return null
	return _state.survivor_state


func get_survivor_system() -> SurvivorSystem:
	return _survivor_system


func get_survivor_definition(survivor_id: StringName) -> SurvivorDefinition:
	if _data_registry == null or not _data_registry.has_survivor(survivor_id):
		return null
	return _data_registry.get_survivor(survivor_id)


func get_skill_definition(skill_id: StringName) -> SkillDefinition:
	if _data_registry == null or not _data_registry.has_skill(skill_id):
		return null
	return _data_registry.get_skill(skill_id)


func get_boss_definition(boss_id: StringName) -> BossDefinition:
	if _data_registry == null or not _data_registry.has_boss(boss_id):
		return null
	return _data_registry.get_boss(boss_id)


func get_battle_state() -> BattleState:
	if not has_active_state():
		return null
	return _state.battle_state


func get_battle_system() -> BattleSystem:
	return _battle_system


func can_perform_survival_action(action_type: StringName) -> SurvivalActionResult:
	if not has_active_state():
		return SurvivalActionResult.failure(
			action_type,
			SurvivalSystem.ERROR_INVALID_SURVIVAL_STATE,
			GameText.get_text(&"message.session.start_before_operating"),
		)
	return _survival_system.can_perform_action(_state.survival_state, action_type)


func consume_survival_action_stamina(action_type: StringName) -> SurvivalActionResult:
	if not has_active_state():
		return SurvivalActionResult.failure(
			action_type,
			SurvivalSystem.ERROR_INVALID_SURVIVAL_STATE,
			GameText.get_text(&"message.session.start_before_operating"),
		)
	return _survival_system.consume_action_stamina(_state.survival_state, action_type)


func apply_survival_durability_loss(source_id: StringName, amount: float) -> SurvivalActionResult:
	if not has_active_state():
		return SurvivalActionResult.failure(
			source_id,
			SurvivalSystem.ERROR_INVALID_SURVIVAL_STATE,
			GameText.get_text(&"message.session.start_before_operating"),
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
		return CommandResult.failure(&"inactive_session", GameText.get_text(&"message.session.start_before_building"))
	return _building_system.execute(_state, command)


func execute_upgrade_building(command: UpgradeBuildingCommand) -> CommandResult:
	if not has_active_state():
		return CommandResult.failure(&"inactive_session", GameText.get_text(&"message.session.start_before_building"))
	return _building_system.upgrade(_state, command)


func execute_gather_resources(command: GatherResourcesCommand) -> CommandResult:
	if not has_active_state():
		return CommandResult.failure(&"inactive_session", GameText.get_text(&"message.session.start_before_gathering"))
	return _gathering_system.execute(_state, command)


func execute_use_food(command: UseFoodCommand) -> CommandResult:
	if not has_active_state() or command == null:
		return CommandResult.failure(&"inactive_session", GameText.get_text(&"message.session.start_before_use_supplies"))
	if not _data_registry.has_item(command.item_id):
		return CommandResult.failure(&"unknown_item", GameText.get_text(&"message.session.item_unavailable"))
	var definition: ItemDefinition = _data_registry.get_item(command.item_id)
	if definition.supply_restore_amount <= 0.0:
		return CommandResult.failure(&"not_food", GameText.get_text(&"message.session.item_not_food"))
	var config: SurvivalConfigDefinition = _survival_system.get_config(_state.survival_state)
	if config == null or _state.survival_state.supply >= config.max_supply:
		return CommandResult.failure(&"supply_full", GameText.get_text(&"message.session.supplies_full"))
	var cost: Dictionary[StringName, int] = {command.item_id: 1}
	if not _inventory_system.spend_cost(_state.inventory_state, cost):
		return CommandResult.failure(&"insufficient_resources", GameText.get_text(&"message.session.no_food"))
	if not _survival_system.restore_supply(_state.survival_state, definition.supply_restore_amount):
		return CommandResult.failure(&"supply_full", GameText.get_text(&"message.session.supplies_full"))
	return CommandResult.success(GameText.format(&"message.session.supplies_restored", [definition.supply_restore_amount]))


func execute_set_production_enabled(command: SetProductionEnabledCommand) -> CommandResult:
	if not has_active_state():
		return CommandResult.failure(&"inactive_session", GameText.get_text(&"message.session.start_before_operating"))
	return _production_system.set_enabled(_state, command.building_instance_id, command.is_enabled)


func execute_recruit_survivor(command: RecruitSurvivorCommand) -> CommandResult:
	if not has_active_state() or command == null:
		return CommandResult.failure(&"inactive_session", GameText.get_text(&"message.session.start_before_recruiting"))
	return _survivor_system.recruit(_state, command.survivor_id)


func execute_upgrade_survivor(command: UpgradeSurvivorCommand) -> CommandResult:
	if not has_active_state() or command == null:
		return CommandResult.failure(&"inactive_session", GameText.get_text(&"message.session.start_before_recruiting"))
	return _survivor_system.upgrade(_state, command.survivor_id)


func execute_set_lineup(command: SetLineupCommand) -> CommandResult:
	if not has_active_state() or command == null:
		return CommandResult.failure(&"inactive_session", GameText.get_text(&"message.session.start_before_recruiting"))
	return _survivor_system.set_lineup(_state.survivor_state, command.lineup_ids)


func get_production_system() -> ProductionSystem:
	return _production_system


func get_exploration_system() -> ExplorationSystem:
	return _exploration_system


func get_region_definition(region_id: StringName) -> RegionDefinition:
	return _exploration_system.get_region_definition(region_id) if _exploration_system != null else null


func get_reachable_regions() -> Array[RegionDefinition]:
	if not has_active_state():
		return []
	return _exploration_system.get_reachable_regions(_state.world_state)


func is_exploration_unlocked() -> bool:
	return has_active_state() and _exploration_system.is_unlocked(_state)


func execute_explore_region(command: ExploreRegionCommand) -> CommandResult:
	if not has_active_state():
		return CommandResult.failure(&"inactive_session", GameText.get_text(&"message.session.start_before_sailing"))
	var result: ExplorationResult = _exploration_system.execute(_state, command)
	_last_exploration_result = result if result.succeeded else null
	if not result.succeeded:
		return CommandResult.failure(result.error_code, result.message)
	return CommandResult.success(result.message)


func execute_start_battle(command: StartBattleCommand) -> CommandResult:
	if not has_active_state() or command == null:
		return CommandResult.failure(&"inactive_session", GameText.get_text(&"message.session.start_before_battle"))
	var start_validation: BattleActionResult = _battle_system.can_start(_state, command.boss_id)
	if not start_validation.succeeded:
		return CommandResult.failure(start_validation.error_code, start_validation.message)
	if not _can_settle_battle_victory(command.boss_id):
		return CommandResult.failure(&"battle_settlement_failed", GameText.get_text(&"message.battle.settlement_failed"))
	var precheck: SurvivalActionResult = consume_survival_action_stamina(SurvivalSystem.ACTION_BATTLE)
	if not precheck.succeeded:
		return CommandResult.failure(precheck.error_code, precheck.message)
	var result: BattleActionResult = _battle_system.start(_state, command.boss_id)
	_last_battle_action_result = result
	if not result.succeeded:
		return CommandResult.failure(result.error_code, result.message)
	return CommandResult.success(result.message)


func execute_battle_action(command: BattleActionCommand) -> CommandResult:
	if not has_active_state() or command == null:
		return CommandResult.failure(&"inactive_session", GameText.get_text(&"message.session.start_before_battle"))
	var result: BattleActionResult = _battle_system.perform_action(_state, command.actor_id, command.use_skill)
	_last_battle_action_result = result
	if not result.succeeded:
		return CommandResult.failure(result.error_code, result.message)
	if result.battle_completed and not _settle_completed_battle():
		return CommandResult.failure(&"battle_settlement_failed", GameText.get_text(&"message.battle.settlement_failed"))
	return CommandResult.success(result.message)


func execute_return_from_battle(_command: ReturnFromBattleCommand) -> CommandResult:
	if not has_active_state():
		return CommandResult.failure(&"inactive_session", GameText.get_text(&"message.session.start_before_battle"))
	var result: BattleActionResult = _battle_system.dismiss_completed(_state)
	_last_battle_action_result = result
	if not result.succeeded:
		return CommandResult.failure(result.error_code, result.message)
	return CommandResult.success(result.message)


func _settle_completed_battle() -> bool:
	var battle: BattleState = _state.battle_state
	if battle == null or battle.status != BattleState.Status.COMPLETED or battle.settlement_applied:
		return battle != null and battle.settlement_applied
	var boss: BossDefinition = get_boss_definition(battle.boss_id)
	if boss == null:
		return false
	if battle.did_win:
		var reward: RewardDefinition = _data_registry.get_reward(boss.reward_id)
		if reward == null:
			return false
		for item_id: StringName in reward.item_rewards:
			if not _inventory_system.can_add(_state.inventory_state, item_id, reward.item_rewards[item_id], _inventory_system.get_capacity(_state, item_id)):
				return false
		for item_id: StringName in reward.item_rewards:
			if not _inventory_system.add(_state.inventory_state, item_id, reward.item_rewards[item_id], _inventory_system.get_capacity(_state, item_id)):
				return false
		if not _survivor_system.grant_lineup_experience(_state.survivor_state, reward.survivor_experience):
			return false
		if boss.victory_durability_loss > 0.0:
			_survival_system.apply_durability_loss(_state.survival_state, boss.id, boss.victory_durability_loss)
	else:
		if boss.defeat_durability_loss > 0.0:
			_survival_system.apply_durability_loss(_state.survival_state, boss.id, boss.defeat_durability_loss)
	battle.settlement_applied = true
	return true


func _can_settle_battle_victory(boss_id: StringName) -> bool:
	var boss: BossDefinition = get_boss_definition(boss_id)
	if boss == null:
		return false
	var reward: RewardDefinition = _data_registry.get_reward(boss.reward_id)
	if reward == null:
		return false
	for item_id: StringName in reward.item_rewards:
		if not _inventory_system.can_add(_state.inventory_state, item_id, reward.item_rewards[item_id], _inventory_system.get_capacity(_state, item_id)):
			return false
	return true
