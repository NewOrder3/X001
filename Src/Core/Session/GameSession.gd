class_name GameSession
extends RefCounted

## Owns the state for one new-game or loaded-game runtime lifecycle.

var _state: GameState = null
var _world_seed: int = 0
var _is_disposed: bool = false


func create_new_game(world_seed: int) -> void:
	_world_seed = world_seed
	_state = GameState.new(world_seed)
	_is_disposed = false


func load_state(state: GameState) -> void:
	assert(state != null, "GameSession.load_state requires a GameState.")
	if state == null:
		return

	_state = state
	_world_seed = state.world_seed
	_is_disposed = false


func dispose() -> void:
	_state = null
	_world_seed = 0
	_is_disposed = true


func has_active_state() -> bool:
	return not _is_disposed and _state != null


func get_state() -> GameState:
	assert(has_active_state(), "GameSession has no active GameState.")
	return _state


func get_world_seed() -> int:
	return _world_seed
