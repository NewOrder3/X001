extends "res://Tests/TestCase.gd"


func test_game_menu_pauses_saves_and_resumes() -> void:
	var game_root: Node = preload("res://Scenes/Game/GameRoot.tscn").instantiate()
	Engine.get_main_loop().root.add_child(game_root)
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(21), session.get_last_error())
	game_root.bind_session(session)
	var menu: GameMenuPanel = game_root.get_node("UIRoot/WindowLayer/GameMenuPanel") as GameMenuPanel
	assert_not_null(menu)
	if menu == null:
		game_root.free()
		return

	game_root._open_menu()
	assert_true(menu.visible)
	assert_false(session.get_simulation_clock().is_running())

	menu._save_game()
	assert_true(SaveService.new().has_save(&"main"))

	game_root._close_menu()
	assert_false(menu.visible)
	assert_true(session.get_simulation_clock().is_running())
	game_root.free()

	var save_path: String = ProjectSettings.globalize_path("user://saves/main.json")
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
	var backup_path: String = "%s.bak" % save_path
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(backup_path)
