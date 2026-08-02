extends SceneTree


func _init() -> void:
	var session: GameSession = GameSession.new()
	session.create_new_game(101)
	if not session.has_active_state() or session.get_world_seed() != 101:
		_fail("New game did not create an active state with its seed.")
		return

	var first_state: GameState = session.get_state()
	var loaded_state: GameState = GameState.new(202)
	var expected_raft_state: RaftState = RaftState.new()
	loaded_state.raft_state = expected_raft_state
	session.load_state(loaded_state)
	if session.get_state() != loaded_state or session.get_state().raft_state != expected_raft_state:
		_fail("Loaded GameState was not retained accurately.")
		return
	if session.get_world_seed() != 202:
		_fail("Loaded GameState seed was not retained accurately.")
		return

	session.dispose()
	if session.has_active_state():
		_fail("Disposed session still reports active state.")
		return

	session.create_new_game(303)
	if session.get_state() == first_state or session.get_world_seed() != 303:
		_fail("New game after dispose retained old state.")
		return

	print("GameSession lifecycle validation passed.")
	quit(0)


func _fail(message: String) -> void:
	printerr("SESSION: %s" % message)
	quit(1)
