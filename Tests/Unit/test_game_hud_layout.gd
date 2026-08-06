extends "res://Tests/TestCase.gd"


func test_wide_and_compact_hud_keep_primary_regions_separate() -> void:
	var game_root: Node = preload("res://Scenes/Game/GameRoot.tscn").instantiate()
	Engine.get_main_loop().root.add_child(game_root)
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(42), session.get_last_error())
	game_root.bind_session(session)
	var hud: GameHudLayout = game_root.get_node("UIRoot/HUDLayer/GameHudLayout") as GameHudLayout
	assert_not_null(hud)
	if hud == null:
		game_root.free()
		return

	hud._apply_wide_layout(Vector2(1280.0, 720.0))
	_assert_no_overlap(_get_rect(hud, "ResourceRibbon"), _get_rect(hud, "CurrentGoalHud"), "wide resources and current goal overlap")
	_assert_no_overlap(_get_rect(hud, "CurrentGoalHud"), _get_rect(hud, "SurvivalHUD"), "wide goal and survival HUD overlap")
	_assert_no_overlap(_get_rect(hud, "BuildConfirmBar"), _get_rect(hud, "BottomNavigation"), "wide build confirmation and navigation overlap")
	_assert_no_overlap(_get_rect(hud, "BottomNavigation"), _get_rect(hud, "MoreMenu"), "wide navigation and more menu overlap")

	hud._apply_compact_layout(Vector2(800.0, 600.0))
	_assert_no_overlap(_get_rect(hud, "ResourceRibbon"), _get_rect(hud, "SurvivalHUD"), "compact resources and survival HUD overlap")
	_assert_no_overlap(_get_rect(hud, "SurvivalHUD"), _get_rect(hud, "MenuButton"), "compact survival HUD and menu overlap")
	_assert_no_overlap(_get_rect(hud, "ResourceRibbon"), _get_rect(hud, "MenuButton"), "compact resources and menu overlap")
	_assert_no_overlap(_get_rect(hud, "CurrentGoalHud"), _get_rect(hud, "QuestFeedbackBanner"), "compact goal and feedback overlap")
	_assert_no_overlap(_get_rect(hud, "QuestFeedbackBanner"), _get_rect(hud, "MoreMenu"), "compact feedback and more menu overlap")
	_assert_no_overlap(_get_rect(hud, "BuildConfirmBar"), _get_rect(hud, "MoreMenu"), "compact build confirmation and more menu overlap")
	_assert_no_overlap(_get_rect(hud, "MoreMenu"), _get_rect(hud, "BottomNavigation"), "compact more menu and navigation overlap")
	game_root.free()


func test_non_map_panels_show_the_built_raft_without_disabling_map_exploration() -> void:
	var game_root: Node = preload("res://Scenes/Game/GameRoot.tscn").instantiate()
	Engine.get_main_loop().root.add_child(game_root)
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(59), session.get_last_error())
	game_root.bind_session(session)
	var hud: GameHudLayout = game_root.get_node("UIRoot/HUDLayer/GameHudLayout") as GameHudLayout
	var raft_view: RaftBuildView = game_root.get_node("RaftBuildView") as RaftBuildView
	var ocean_map: Node2D = game_root.get_node("DynamicOceanMap") as Node2D
	assert_not_null(hud)
	assert_not_null(raft_view)
	assert_not_null(ocean_map)
	if hud == null or raft_view == null or ocean_map == null:
		game_root.free()
		return

	hud.open_panel(&"supply")
	assert_true(raft_view.visible)
	assert_false(raft_view._is_interaction_enabled)
	assert_true(raft_view._show_salvage_spots)
	assert_false(ocean_map.visible)

	hud.open_panel(&"crew")
	assert_true(raft_view.visible)
	assert_false(raft_view._is_interaction_enabled)
	assert_false(raft_view._show_salvage_spots)
	assert_false(ocean_map.visible)

	hud.open_panel(&"map")
	assert_false(raft_view.visible)
	assert_true(ocean_map.visible)
	game_root.free()


func _get_rect(hud: GameHudLayout, node_path: String) -> Rect2:
	var control: Control = hud.get_node(node_path) as Control
	return Rect2(control.position, control.size)


func _assert_no_overlap(first: Rect2, second: Rect2, message: String) -> void:
	assert_false(first.intersects(second), message)
