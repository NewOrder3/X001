extends "res://Tests/TestCase.gd"


func test_battle_entry_deducts_stamina_once_and_defeats_boss_with_skill() -> void:
	var session: GameSession = _create_lineup_session()
	var state: GameState = session.get_state()
	var stamina_before: int = state.survival_state.stamina
	var stamina_cost: int = session.get_survival_system().get_config(state.survival_state).battle_stamina_cost
	var durability_before: float = state.survival_state.durability
	var wood_before: int = session.get_item_amount(&"item_wood")

	var start_result: CommandResult = session.execute_command(StartBattleCommand.new(&"boss_tutorial_sea_beast"))
	assert_true(start_result.succeeded, start_result.message)
	assert_eq(state.survival_state.stamina, stamina_before - stamina_cost)
	assert_eq(state.battle_state.status, BattleState.Status.ACTIVE)
	var skill_result: CommandResult = session.execute_command(BattleActionCommand.new(&"survivor_marin", true))
	assert_true(skill_result.succeeded, skill_result.message)
	while state.battle_state.status == BattleState.Status.ACTIVE:
		var attack_result: CommandResult = session.execute_command(BattleActionCommand.new(&"survivor_marin", false))
		assert_true(attack_result.succeeded, attack_result.message)

	assert_true(state.battle_state.did_win)
	assert_true(state.battle_state.settlement_applied)
	assert_eq(state.survival_state.stamina, stamina_before - stamina_cost)
	assert_eq(session.get_item_amount(&"item_wood"), wood_before + 4)
	assert_eq(session.get_item_amount(&"item_grilled_fish"), 1)
	assert_eq(state.survivor_state.survivors[&"survivor_marin"].experience, 10)
	assert_eq(state.survival_state.durability, durability_before - 4.0)


func test_battle_entry_rejects_depleted_durability_without_spending_stamina() -> void:
	var session: GameSession = _create_lineup_session()
	var state: GameState = session.get_state()
	state.survival_state.durability = 0.0
	var stamina_before: int = state.survival_state.stamina

	var result: CommandResult = session.execute_command(StartBattleCommand.new(&"boss_tutorial_sea_beast"))

	assert_false(result.succeeded)
	assert_eq(result.error_code, SurvivalSystem.ERROR_DURABILITY_DEPLETED)
	assert_eq(state.survival_state.stamina, stamina_before)
	assert_eq(state.battle_state.status, BattleState.Status.IDLE)


func test_skill_cooldown_rejection_does_not_mutate_battle_state() -> void:
	var session: GameSession = _create_lineup_session()
	assert_true(session.execute_command(StartBattleCommand.new(&"boss_tutorial_sea_beast")).succeeded)
	assert_true(session.execute_command(BattleActionCommand.new(&"survivor_marin", true)).succeeded)
	var battle: BattleState = session.get_battle_state()
	var health_before: int = battle.boss_current_health
	var cooldown_before: int = battle.skill_cooldowns[&"survivor_marin"]
	var turn_before: int = battle.turn_number

	var result: CommandResult = session.execute_command(BattleActionCommand.new(&"survivor_marin", true))

	assert_false(result.succeeded)
	assert_eq(result.error_code, BattleSystem.ERROR_SKILL_COOLDOWN)
	assert_eq(battle.boss_current_health, health_before)
	assert_eq(battle.skill_cooldowns[&"survivor_marin"], cooldown_before)
	assert_eq(battle.turn_number, turn_before)


func test_active_battle_round_trips_through_save_data() -> void:
	var session: GameSession = _create_lineup_session()
	assert_true(session.execute_command(StartBattleCommand.new(&"boss_tutorial_sea_beast")).succeeded)
	assert_true(session.execute_command(BattleActionCommand.new(&"survivor_marin", true)).succeeded)
	var expected_health: int = session.get_battle_state().boss_current_health
	var service: SaveService = SaveService.new()
	service.set_active_state(session.get_state())
	assert_true(service.save_game(&"battle_state_test", 1_710_000_000))
	var loaded_state: GameState = service.load_game(&"battle_state_test")

	assert_not_null(loaded_state)
	if loaded_state == null:
		return
	assert_eq(loaded_state.battle_state.status, BattleState.Status.ACTIVE)
	assert_eq(loaded_state.battle_state.boss_id, &"boss_tutorial_sea_beast")
	assert_eq(loaded_state.battle_state.boss_current_health, expected_health)
	var loaded_session: GameSession = GameSession.new()
	assert_true(loaded_session.load_state_at(loaded_state, 1_710_000_000), loaded_session.get_last_error())


func test_regional_boss_requires_stronger_lineup_and_settles_rewards() -> void:
	var session: GameSession = _create_lineup_session()
	var state: GameState = session.get_state()
	assert_true(session.execute_command(UpgradeRaftCommand.new()).succeeded)
	assert_true(session.execute_command(GatherResourcesCommand.new(&"item_wood", 6)).succeeded)
	assert_true(session.execute_command(UpgradeSurvivorCommand.new(&"survivor_marin")).succeeded)
	assert_true(session.execute_command(UpgradeSurvivorCommand.new(&"survivor_marin")).succeeded)
	var stamina_before: int = state.survival_state.stamina
	var durability_before: float = state.survival_state.durability
	var wood_before: int = session.get_item_amount(&"item_wood")

	var start_result: CommandResult = session.execute_command(StartBattleCommand.new(&"boss_reef_leviathan"))
	assert_true(start_result.succeeded, start_result.message)
	assert_eq(state.survival_state.stamina, stamina_before - 1)
	assert_true(session.execute_command(BattleActionCommand.new(&"survivor_marin", true)).succeeded)
	while state.battle_state.status == BattleState.Status.ACTIVE:
		var attack_result: CommandResult = session.execute_command(BattleActionCommand.new(&"survivor_marin", false))
		assert_true(attack_result.succeeded, attack_result.message)

	assert_true(state.battle_state.did_win)
	assert_true(state.battle_state.settlement_applied)
	assert_eq(state.survival_state.stamina, stamina_before - 1)
	assert_eq(session.get_item_amount(&"item_wood"), wood_before + 8)
	assert_eq(session.get_item_amount(&"item_grilled_fish"), 2)
	assert_eq(session.get_item_amount(&"item_fresh_water"), 2)
	assert_eq(state.survivor_state.survivors[&"survivor_marin"].experience, 25)
	assert_eq(state.survival_state.durability, durability_before - 6.0)


func _create_lineup_session() -> GameSession:
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(801), session.get_last_error())
	var survivor_system: SurvivorSystem = session.get_survivor_system()
	var survivor_state: SurvivorState = session.get_survivor_state()
	assert_true(survivor_system.offer_recruitment(survivor_state, &"survivor_marin"))
	assert_true(session.execute_command(RecruitSurvivorCommand.new(&"survivor_marin")).succeeded)
	assert_true(session.execute_command(SetLineupCommand.new([&"survivor_marin"])).succeeded)
	return session
