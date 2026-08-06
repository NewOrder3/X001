extends "res://Tests/TestCase.gd"


func test_clicking_the_center_of_the_raft_selects_its_center_cell() -> void:
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(17), session.get_last_error())
	var build_view: RaftBuildView = RaftBuildView.new()
	build_view.position = Vector2(960.0, 520.0)
	build_view.bind_session(session)
	build_view.select_building(&"building_rain_collector")
	var selected_cells: Array[Vector2i] = []
	build_view.tile_selected.connect(func(cell: Vector2i) -> void:
		selected_cells.append(cell)
	)

	var click_event: InputEventMouseButton = InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	click_event.position = Vector2(960.0, 520.0)
	build_view._unhandled_input(click_event)

	assert_eq(selected_cells.size(), 1)
	assert_eq(selected_cells[0], Vector2i.ZERO)
	build_view.free()


func test_full_screen_ui_layers_do_not_block_raft_input() -> void:
	var ui_root: CanvasLayer = preload("res://Scenes/UI/UIRoot.tscn").instantiate() as CanvasLayer
	assert_not_null(ui_root)
	if ui_root == null:
		return
	assert_eq(ui_root.layer, 100)
	assert_eq((ui_root.get_node("HUDLayer") as Control).mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_eq((ui_root.get_node("WindowLayer") as Control).mouse_filter, Control.MOUSE_FILTER_IGNORE)
	ui_root.free()
