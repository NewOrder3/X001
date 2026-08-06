extends SceneTree

## Scripted new-player loop for balance checks.
## It simulates one playthrough with per-action time estimates, prints milestone
## stats, and fails when the loop cannot be completed or survival collapses.

const ACTION_SECONDS: float = 6.0
const TRAVEL_SECONDS: float = 2.0
const BATTLE_TURN_SECONDS: float = 3.0

var _session: GameSession = null
var _in_game_seconds: float = 0.0
var _real_seconds: float = 0.0
var _build_cell_index: int = 0


func _init() -> void:
	var reference_seed: int = _find_reference_seed()
	if reference_seed <= 0:
		printerr("PLAYTEST: No reference seed in 1..512 supports the intended rescue path.")
		quit(1)
		return
	print("PLAYTEST: reference seed = %d" % reference_seed)
	if not _run_loop(reference_seed):
		quit(1)
		return
	print("PLAYTEST: loop completed in %d in-game minutes, estimated %d real minutes." % [
		int(_in_game_seconds / 60.0),
		int(_real_seconds / 60.0),
	])
	quit(0)


func _find_reference_seed() -> int:
	for seed: int in range(1, 513):
		if _seed_has_bo_at_west(seed) and _seed_has_marin_at_east(seed):
			return seed
	return 0


func _seed_has_bo_at_west(seed: int) -> bool:
	var session: GameSession = GameSession.new()
	if not session.create_new_game(seed):
		return false
	if not _try_build_rudder(session):
		return false
	var result: ExplorationResult = _explore(session, &"region_west_shoals")
	return result != null and result.rescued_survivor_id == &"survivor_bo"


func _seed_has_marin_at_east(seed: int) -> bool:
	var session: GameSession = GameSession.new()
	if not session.create_new_game(seed):
		return false
	if not _try_build_rudder(session):
		return false
	var result: ExplorationResult = _explore(session, &"region_east_current")
	return result != null and result.rescued_survivor_id == &"survivor_marin"


func _try_build_rudder(session: GameSession) -> bool:
	var result: CommandResult = session.execute_command(
		PlaceBuildingCommand.new(&"building_rudder", Vector2i(0, 0), 0)
	)
	return result.succeeded


func _explore(session: GameSession, region_id: StringName) -> ExplorationResult:
	var result: CommandResult = session.execute_command(ExploreRegionCommand.new(region_id))
	if not result.succeeded:
		return null
	return session.get_last_exploration_result()


func _run_loop(seed: int) -> bool:
	_session = GameSession.new()
	if not _session.create_new_game(seed):
		printerr("PLAYTEST: create_new_game failed: %s" % _session.get_last_error())
		return false
	_record_milestone("start")

	_gather_until(&"item_wood", 3)
	if not _build(&"building_rain_collector"):
		return false
	_record_milestone("rain collector")

	_wait(60.0)
	if _session.get_item_amount(&"item_fresh_water") >= 1:
		_use_food(&"item_fresh_water")
	_record_milestone("water + use")

	_gather_until(&"item_wood", 5)
	if not _build(&"building_rudder"):
		return false
	_record_milestone("rudder")

	var west: ExplorationResult = _explore(_session, &"region_west_shoals")
	if west == null or west.rescued_survivor_id != &"survivor_bo":
		printerr("PLAYTEST: west shoals did not rescue Bo for the reference seed.")
		return false
	_recruit(&"survivor_bo")
	var back: ExplorationResult = _explore(_session, &"region_starting_sea")
	if back == null:
		printerr("PLAYTEST: could not sail back to the starting sea.")
		return false
	var east: ExplorationResult = _explore(_session, &"region_east_current")
	if east == null or east.rescued_survivor_id != &"survivor_marin":
		printerr("PLAYTEST: east current did not rescue Marin for the reference seed.")
		return false
	_recruit(&"survivor_marin")
	_set_lineup([&"survivor_marin", &"survivor_bo"])
	_record_milestone("crew + lineup")

	_gather_until(&"item_wood", 8)
	if not _upgrade_raft():
		return false
	_record_milestone("raft lv2")

	_gather_until(&"item_wood", 4)
	if not _build(&"building_campfire"):
		return false
	_gather_until(&"item_raw_fish", 2)
	_wait(40.0)
	if _session.get_item_amount(&"item_grilled_fish") >= 1:
		_use_food(&"item_grilled_fish")
	_record_milestone("campfire + grill")

	if not _fight(&"boss_tutorial_sea_beast"):
		return false
	_record_milestone("tutorial boss")

	_gather_until(&"item_wood", 4)
	if not _upgrade_survivor(&"survivor_marin"):
		return false
	if not _upgrade_survivor(&"survivor_marin"):
		return false
	if not _fight(&"boss_reef_leviathan"):
		return false
	_record_milestone("reef boss")

	_gather_until(&"item_wood", 2)
	if not _buy_merchant(&"offer_fresh_water"):
		return false
	_record_milestone("merchant")
	return true


func _gather_until(item_id: StringName, target_amount: int) -> void:
	while _session.get_item_amount(item_id) < target_amount:
		var result: CommandResult = _session.execute_command(GatherResourcesCommand.new(item_id, 1))
		if not result.succeeded:
			printerr("PLAYTEST: gather %s failed: %s" % [String(item_id), result.message])
			return
		_action(ACTION_SECONDS)


func _build(building_id: StringName) -> bool:
	var cell: Vector2i = _next_build_cell()
	var result: CommandResult = _session.execute_command(PlaceBuildingCommand.new(building_id, cell, 0))
	_action(ACTION_SECONDS)
	if not result.succeeded:
		printerr("PLAYTEST: build %s failed: %s" % [String(building_id), result.message])
		return false
	return true


func _next_build_cell() -> Vector2i:
	var cell: Vector2i = Vector2i(_build_cell_index % 3, _build_cell_index / 3)
	_build_cell_index += 1
	return cell


func _upgrade_raft() -> bool:
	var result: CommandResult = _session.execute_command(UpgradeRaftCommand.new())
	_action(ACTION_SECONDS)
	if not result.succeeded:
		printerr("PLAYTEST: raft upgrade failed: %s" % result.message)
		return false
	return true


func _upgrade_survivor(survivor_id: StringName) -> bool:
	var result: CommandResult = _session.execute_command(UpgradeSurvivorCommand.new(survivor_id))
	_action(ACTION_SECONDS)
	if not result.succeeded:
		printerr("PLAYTEST: survivor upgrade failed: %s" % result.message)
		return false
	return true


func _recruit(survivor_id: StringName) -> void:
	_session.execute_command(RecruitSurvivorCommand.new(survivor_id))
	_action(ACTION_SECONDS)


func _set_lineup(lineup_ids: Array[StringName]) -> void:
	_session.execute_command(SetLineupCommand.new(lineup_ids))
	_action(ACTION_SECONDS)


func _use_food(item_id: StringName) -> void:
	if _session.get_survival_state().supply > 80.0:
		return
	var result: CommandResult = _session.execute_command(UseFoodCommand.new(item_id))
	if not result.succeeded:
		printerr("PLAYTEST: use food %s failed: %s" % [String(item_id), result.message])
	_action(ACTION_SECONDS)


func _buy_merchant(offer_id: StringName) -> bool:
	var result: CommandResult = _session.execute_command(BuyMerchantItemCommand.new(offer_id))
	_action(ACTION_SECONDS)
	if not result.succeeded:
		printerr("PLAYTEST: merchant buy failed: %s" % result.message)
		return false
	return true


func _fight(boss_id: StringName) -> bool:
	var start_result: CommandResult = _session.execute_command(StartBattleCommand.new(boss_id))
	_action(ACTION_SECONDS)
	if not start_result.succeeded:
		printerr("PLAYTEST: battle start %s failed: %s" % [String(boss_id), start_result.message])
		return false
	var used_skill: bool = false
	var battle: BattleState = _session.get_battle_state()
	while battle.status == BattleState.Status.ACTIVE:
		var actor_id: StringName = battle.party_health.keys()[0]
		var action_result: CommandResult = _session.execute_command(
			BattleActionCommand.new(actor_id, not used_skill)
		)
		used_skill = true
		_action(BATTLE_TURN_SECONDS)
		if not action_result.succeeded:
			printerr("PLAYTEST: battle action failed: %s" % action_result.message)
			return false
	if not battle.did_win:
		printerr("PLAYTEST: battle %s was lost." % String(boss_id))
		return false
	var return_result: CommandResult = _session.execute_command(ReturnFromBattleCommand.new())
	_action(ACTION_SECONDS)
	if not return_result.succeeded:
		printerr("PLAYTEST: returning from battle failed: %s" % return_result.message)
		return false
	return true


func _wait(seconds: float) -> void:
	for _second: int in range(int(seconds)):
		_session.advance_simulation(1.0)
	_in_game_seconds += seconds
	_real_seconds += seconds


func _action(seconds: float) -> void:
	_real_seconds += seconds
	for _second: int in range(int(seconds)):
		_session.advance_simulation(1.0)
	_in_game_seconds += seconds


func _record_milestone(label: String) -> void:
	var survival: SurvivalState = _session.get_survival_state()
	print(
		"PLAYTEST: %-14s in=%4dmin real=%4dmin supply=%5.1f dur=%5.1f stamina=%2d wood=%3d" % [
			label,
			int(_in_game_seconds / 60.0),
			int(_real_seconds / 60.0),
			survival.supply,
			survival.durability,
			survival.stamina,
			_session.get_item_amount(&"item_wood"),
		]
	)
