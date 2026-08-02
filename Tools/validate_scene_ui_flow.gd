extends SceneTree

func _init() -> void:
	var bootstrap: Node = preload("res://Scenes/Bootstrap/Bootstrap.tscn").instantiate()
	root.add_child(bootstrap)
	var router: SceneRouter = bootstrap.get_node("SceneRouter") as SceneRouter
	var session: GameSession = GameSession.new()
	session.create_new_game(321)
	router.enter_game(session)
	var game_root: GameRoot = router.get_current_scene() as GameRoot
	if game_root == null or game_root.get_session() != session:
		_fail("Game scene did not retain its session.")
		return
	router.enter_battle({"test": true})
	var battle_root: BattleRoot = router.get_current_scene() as BattleRoot
	if battle_root == null or battle_root.get_session() != session:
		_fail("Battle scene did not retain its session.")
		return
	router.return_to_game()
	if not router.get_current_scene() is GameRoot:
		_fail("Return to game did not restore GameRoot.")
		return
	print("Scene and UI flow validation passed.")
	quit(0)

func _fail(message: String) -> void:
	printerr("SCENE: %s" % message)
	quit(1)
