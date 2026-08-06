extends "res://Tests/TestCase.gd"


func test_build_confirm_and_cancel_shortcuts() -> void:
	var game_root: Node = preload("res://Scenes/Game/GameRoot.tscn").instantiate()
	Engine.get_main_loop().root.add_child(game_root)
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(22), session.get_last_error())
	game_root.bind_session(session)
	var hud: GameHudLayout = game_root.get_node("UIRoot/HUDLayer/GameHudLayout") as GameHudLayout
	hud.open_panel(&"build")
	var build_panel: RaftBuildPanel = game_root.get_node(
		"UIRoot/HUDLayer/GameHudLayout/LeftPanelScroll/LeftPanelColumn/RaftBuildPanel"
	) as RaftBuildPanel
	var build_view: RaftBuildView = game_root.get_node("RaftBuildView") as RaftBuildView

	build_panel._select_building(&"building_rain_collector")
	var click_event: InputEventMouseButton = InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	click_event.position = Vector2(960.0, 520.0)
	build_view._unhandled_input(click_event)
	assert_true(build_panel._has_selected_cell)

	var enter_event: InputEventKey = InputEventKey.new()
	enter_event.keycode = KEY_ENTER
	enter_event.pressed = true
	build_panel._unhandled_input(enter_event)
	var has_collector: bool = false
	for instance: BuildingInstance in session.get_raft_state().building_instances.values():
		if instance.building_id == &"building_rain_collector":
			has_collector = true
	assert_true(has_collector)

	build_panel._select_building(&"building_campfire")
	var escape_event: InputEventKey = InputEventKey.new()
	escape_event.keycode = KEY_ESCAPE
	escape_event.pressed = true
	build_panel._unhandled_input(escape_event)
	assert_eq(build_panel._selected_building_id, &"")
	game_root.free()
