class_name SaveService
extends RefCounted

const CURRENT_SAVE_VERSION: int = 1
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


func save_game(slot_id: StringName) -> bool:
	_last_error = ""
	if _active_state == null:
		return _fail("Cannot save without an active GameState.")
	if not _is_valid_slot_id(slot_id):
		return _fail("Invalid save slot ID '%s'." % String(slot_id))
	if DirAccess.make_dir_recursive_absolute(SAVE_DIRECTORY) != OK:
		return _fail("Cannot create save directory '%s'." % SAVE_DIRECTORY)

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
		"inventory_state": {},
		"survivor_state": {},
		"world_state": {},
		"battle_state": {},
		"progression_state": {},
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
	return state


func _v1_to_v2(data: Dictionary) -> Dictionary:
	return data


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
