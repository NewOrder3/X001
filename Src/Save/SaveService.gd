class_name SaveService
extends RefCounted

const CURRENT_SAVE_VERSION: int = 10
const SAVE_DIRECTORY: String = "user://saves"

var _active_state: GameState = null
var _last_error: String = ""


func new_game(world_seed: int = 0) -> void:
	_active_state = GameState.new(world_seed)
	_last_error = ""


func set_active_state(state: GameState) -> void:
	_active_state = state


func get_active_state() -> GameState:
	return _active_state


func save_game(slot_id: StringName, saved_at_unix_seconds: int = -1) -> bool:
	_last_error = ""
	if _active_state == null:
		return _fail("Cannot save without an active GameState.")
	if not _is_valid_slot_id(slot_id):
		return _fail("Invalid save slot ID '%s'." % String(slot_id))
	if DirAccess.make_dir_recursive_absolute(SAVE_DIRECTORY) != OK:
		return _fail("Cannot create save directory '%s'." % SAVE_DIRECTORY)
	_mark_survival_offline_pending(saved_at_unix_seconds)

	var save_data: Dictionary = {
		"save_version": CURRENT_SAVE_VERSION,
		"world_seed": _active_state.world_seed,
		"game_state": _serialize_game_state(_active_state),
	}
	var save_path: String = _get_save_path(slot_id)
	var temp_path: String = "%s.tmp" % save_path
	var backup_path: String = "%s.bak" % save_path
	var temp_file: FileAccess = FileAccess.open(temp_path, FileAccess.WRITE)
	if temp_file == null:
		return _fail("Cannot write temporary save '%s'." % temp_path)
	temp_file.store_string(JSON.stringify(save_data))
	temp_file.close()

	if FileAccess.file_exists(save_path):
		if FileAccess.file_exists(backup_path):
			DirAccess.remove_absolute(backup_path)
		if DirAccess.rename_absolute(save_path, backup_path) != OK:
			return _fail("Cannot create backup for save '%s'." % save_path)

	if DirAccess.rename_absolute(temp_path, save_path) != OK:
		if FileAccess.file_exists(backup_path):
			DirAccess.rename_absolute(backup_path, save_path)
		return _fail("Cannot finalize save '%s'." % save_path)

	return true


func load_game(slot_id: StringName) -> GameState:
	_last_error = ""
	if not _is_valid_slot_id(slot_id):
		_fail("Invalid save slot ID '%s'." % String(slot_id))
		return null
	var save_path: String = _get_save_path(slot_id)
	if not FileAccess.file_exists(save_path):
		_fail("Save slot '%s' does not exist." % String(slot_id))
		return null

	var save_file: FileAccess = FileAccess.open(save_path, FileAccess.READ)
	if save_file == null:
		_fail("Cannot read save '%s'." % save_path)
		return null
	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(save_file.get_as_text())
	save_file.close()
	if parse_result != OK or typeof(json.data) != TYPE_DICTIONARY:
		_fail("Save '%s' is not valid JSON." % save_path)
		return null

	var migrated_data: Dictionary = migrate(json.data)
	if migrated_data.is_empty():
		return null
	var state: GameState = _deserialize_game_state(migrated_data.get("game_state", {}))
	if state == null:
		return null
	_active_state = state
	return state


func migrate(data: Dictionary) -> Dictionary:
	var version: int = int(data.get("save_version", 1))
	if version > CURRENT_SAVE_VERSION:
		_fail("Save version %d is newer than supported version %d." % [version, CURRENT_SAVE_VERSION])
		return {}
	var migrated_data: Dictionary = data.duplicate(true)
	while version < CURRENT_SAVE_VERSION:
		if version == 1:
			migrated_data = _v1_to_v2(migrated_data)
			version = 2
		elif version == 2:
			migrated_data = _v2_to_v3(migrated_data)
			version = 3
		elif version == 3:
			migrated_data = _v3_to_v4(migrated_data)
			version = 4
		elif version == 4:
			migrated_data = _v4_to_v5(migrated_data)
			version = 5
		elif version == 5:
			migrated_data = _v5_to_v6(migrated_data)
			version = 6
		elif version == 6:
			migrated_data = _v6_to_v7(migrated_data)
			version = 7
		elif version == 7:
			migrated_data = _v7_to_v8(migrated_data)
			version = 8
		elif version == 8:
			migrated_data = _v8_to_v9(migrated_data)
			version = 9
		elif version == 9:
			migrated_data = _v9_to_v10(migrated_data)
			version = 10
		else:
			_fail("No migration exists for save version %d." % version)
			return {}
	migrated_data["save_version"] = CURRENT_SAVE_VERSION
	return migrated_data


func get_last_error() -> String:
	return _last_error


func _serialize_game_state(state: GameState) -> Dictionary:
	return {
		"world_seed": state.world_seed,
		"raft_state": state.raft_state.to_save_data(),
		"inventory_state": state.inventory_state.to_save_data(),
		"survival_state": state.survival_state.to_save_data(),
		"production_state": state.production_state.to_save_data(),
		"merchant_state": state.merchant_state.to_save_data(),
		"survivor_state": state.survivor_state.to_save_data(),
		"world_state": state.world_state.to_save_data(),
		"battle_state": state.battle_state.to_save_data(),
		"progression_state": state.progression_state.to_save_data(),
	}


func _deserialize_game_state(data: Dictionary) -> GameState:
	if not data.has("world_seed"):
		_fail("Save game_state is missing world_seed.")
		return null
	var state: GameState = GameState.new(int(data["world_seed"]))
	var raw_raft_state: Variant = data.get("raft_state")
	if not raw_raft_state is Dictionary or not state.raft_state.load_from_save_data(raw_raft_state):
		_fail("Save game_state contains an invalid raft_state.")
		return null
	var raw_inventory_state: Variant = data.get("inventory_state", {})
	if not raw_inventory_state is Dictionary or not state.inventory_state.load_from_save_data(raw_inventory_state):
		_fail("Save game_state contains an invalid inventory_state.")
		return null
	var raw_survival_state: Variant = data.get("survival_state", {})
	if not raw_survival_state is Dictionary:
		_fail("Save game_state contains an invalid survival_state.")
		return null
	if not raw_survival_state.is_empty() and not state.survival_state.load_from_save_data(raw_survival_state):
		_fail("Save game_state contains an invalid survival_state.")
		return null
	var raw_survivor_state: Variant = data.get("survivor_state", {})
	if not raw_survivor_state is Dictionary or not state.survivor_state.load_from_save_data(raw_survivor_state):
		_fail("Save game_state contains an invalid survivor_state.")
		return null
	var raw_production_state: Variant = data.get("production_state", {})
	if not raw_production_state is Dictionary or not state.production_state.load_from_save_data(raw_production_state):
		_fail("Save game_state contains an invalid production_state.")
		return null
	var raw_merchant_state: Variant = data.get("merchant_state", {})
	if not raw_merchant_state is Dictionary or not state.merchant_state.load_from_save_data(raw_merchant_state):
		_fail("Save game_state contains an invalid merchant_state.")
		return null
	var raw_world_state: Variant = data.get("world_state", {})
	if not raw_world_state is Dictionary or not state.world_state.load_from_save_data(raw_world_state):
		_fail("Save game_state contains an invalid world_state.")
		return null
	var raw_battle_state: Variant = data.get("battle_state", {})
	if not raw_battle_state is Dictionary or not state.battle_state.load_from_save_data(raw_battle_state):
		_fail("Save game_state contains an invalid battle_state.")
		return null
	var raw_progression_state: Variant = data.get("progression_state", {})
	if not raw_progression_state is Dictionary or not state.progression_state.load_from_save_data(raw_progression_state):
		_fail("Save game_state contains an invalid progression_state.")
		return null
	return state


func _v1_to_v2(data: Dictionary) -> Dictionary:
	var migrated_data: Dictionary = data.duplicate(true)
	var raw_game_state: Variant = migrated_data.get("game_state")
	if not raw_game_state is Dictionary:
		_fail("Version 1 save is missing a valid game_state object.")
		return {}

	var game_state_data: Dictionary = raw_game_state.duplicate(true)
	for state_key: String in [
		"inventory_state",
		"merchant_state",
		"survivor_state",
		"world_state",
		"battle_state",
		"progression_state",
	]:
		if not game_state_data.has(state_key):
			game_state_data[state_key] = {}

	migrated_data["game_state"] = game_state_data
	return migrated_data


func _v2_to_v3(data: Dictionary) -> Dictionary:
	var migrated_data: Dictionary = data.duplicate(true)
	var raw_game_state: Variant = migrated_data.get("game_state")
	if not raw_game_state is Dictionary:
		_fail("Version 2 save is missing a valid game_state object.")
		return {}

	var game_state_data: Dictionary = raw_game_state.duplicate(true)
	if not game_state_data.has("survival_state"):
		game_state_data["survival_state"] = {}
	migrated_data["game_state"] = game_state_data
	return migrated_data


func _v3_to_v4(data: Dictionary) -> Dictionary:
	var migrated_data: Dictionary = data.duplicate(true)
	var raw_game_state: Variant = migrated_data.get("game_state")
	if not raw_game_state is Dictionary:
		_fail("Version 3 save is missing a valid game_state object.")
		return {}
	var game_state_data: Dictionary = raw_game_state.duplicate(true)
	if not game_state_data.has("production_state"):
		game_state_data["production_state"] = {}
	migrated_data["game_state"] = game_state_data
	return migrated_data


func _v4_to_v5(data: Dictionary) -> Dictionary:
	var migrated_data: Dictionary = data.duplicate(true)
	var raw_game_state: Variant = migrated_data.get("game_state")
	if not raw_game_state is Dictionary:
		_fail("Version 4 save is missing a valid game_state object.")
		return {}
	var game_state_data: Dictionary = raw_game_state.duplicate(true)
	var raw_survival_state: Variant = game_state_data.get("survival_state", {})
	if not raw_survival_state is Dictionary:
		_fail("Version 4 save contains an invalid survival_state.")
		return {}
	var survival_state_data: Dictionary = raw_survival_state.duplicate(true)
	if not survival_state_data.is_empty():
		if not survival_state_data.has("last_online_unix_seconds"):
			survival_state_data["last_online_unix_seconds"] = 0
		if not survival_state_data.has("last_offline_settlement_unix_seconds"):
			survival_state_data["last_offline_settlement_unix_seconds"] = 0
		if not survival_state_data.has("offline_settlement_pending"):
			survival_state_data["offline_settlement_pending"] = false
	game_state_data["survival_state"] = survival_state_data
	migrated_data["game_state"] = game_state_data
	return migrated_data


func _v5_to_v6(data: Dictionary) -> Dictionary:
	var migrated_data: Dictionary = data.duplicate(true)
	var raw_game_state: Variant = migrated_data.get("game_state")
	if not raw_game_state is Dictionary:
		_fail("Version 5 save is missing a valid game_state object.")
		return {}
	var game_state_data: Dictionary = raw_game_state.duplicate(true)
	if not game_state_data.has("world_state"):
		game_state_data["world_state"] = {}
	migrated_data["game_state"] = game_state_data
	return migrated_data


func _v6_to_v7(data: Dictionary) -> Dictionary:
	var migrated_data: Dictionary = data.duplicate(true)
	var raw_game_state: Variant = migrated_data.get("game_state")
	if not raw_game_state is Dictionary:
		_fail("Version 6 save is missing a valid game_state object.")
		return {}
	var game_state_data: Dictionary = raw_game_state.duplicate(true)
	if not game_state_data.has("survivor_state"):
		game_state_data["survivor_state"] = {}
	migrated_data["game_state"] = game_state_data
	return migrated_data


func _v7_to_v8(data: Dictionary) -> Dictionary:
	var migrated_data: Dictionary = data.duplicate(true)
	var raw_game_state: Variant = migrated_data.get("game_state")
	if not raw_game_state is Dictionary:
		_fail("Version 7 save is missing a valid game_state object.")
		return {}
	var game_state_data: Dictionary = raw_game_state.duplicate(true)
	game_state_data["battle_state"] = {}
	migrated_data["game_state"] = game_state_data
	return migrated_data


func _v8_to_v9(data: Dictionary) -> Dictionary:
	var migrated_data: Dictionary = data.duplicate(true)
	var raw_game_state: Variant = migrated_data.get("game_state")
	if not raw_game_state is Dictionary:
		_fail("Version 8 save is missing a valid game_state object.")
		return {}
	var game_state_data: Dictionary = raw_game_state.duplicate(true)
	var raw_progression_state: Variant = game_state_data.get("progression_state")
	if not raw_progression_state is Dictionary or raw_progression_state.is_empty():
		game_state_data["progression_state"] = {"raft_level": 1}
	migrated_data["game_state"] = game_state_data
	return migrated_data


func _v9_to_v10(data: Dictionary) -> Dictionary:
	var migrated_data: Dictionary = data.duplicate(true)
	var raw_game_state: Variant = migrated_data.get("game_state")
	if not raw_game_state is Dictionary:
		_fail("Version 9 save is missing a valid game_state object.")
		return {}
	var game_state_data: Dictionary = raw_game_state.duplicate(true)
	var raw_merchant_state: Variant = game_state_data.get("merchant_state")
	if not raw_merchant_state is Dictionary or raw_merchant_state.is_empty():
		game_state_data["merchant_state"] = {"stock_remaining": {}}
	migrated_data["game_state"] = game_state_data
	return migrated_data


func _mark_survival_offline_pending(saved_at_unix_seconds: int) -> void:
	if _active_state == null or _active_state.survival_state == null:
		return
	var saved_at: int = saved_at_unix_seconds
	if saved_at < 0:
		saved_at = int(Time.get_unix_time_from_system())
	saved_at = maxi(saved_at, 0)
	_active_state.survival_state.last_online_unix_seconds = saved_at
	_active_state.survival_state.offline_settlement_pending = true


func _get_save_path(slot_id: StringName) -> String:
	return "%s/%s.json" % [SAVE_DIRECTORY, String(slot_id)]


func _is_valid_slot_id(slot_id: StringName) -> bool:
	var value: String = String(slot_id)
	if value.is_empty():
		return false
	for character: String in value:
		var code: int = character.unicode_at(0)
		var is_letter: bool = code >= 97 and code <= 122
		var is_digit: bool = code >= 48 and code <= 57
		if not is_letter and not is_digit and character != "_":
			return false
	return true


func _fail(message: String) -> bool:
	_last_error = message
	push_error("SAVE: %s" % message)
	return false
