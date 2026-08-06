extends "res://Tests/TestCase.gd"


func test_map_panel_enables_sailing_after_rudder_is_built() -> void:
	var game_root: Node = preload("res://Scenes/Game/GameRoot.tscn").instantiate()
	Engine.get_main_loop().root.add_child(game_root)
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(17), session.get_last_error())
	game_root.bind_session(session)
	var world_map_panel: WorldMapPanel = game_root.get_node(
		"UIRoot/HUDLayer/GameHudLayout/LeftPanelScroll/LeftPanelColumn/WorldMapPanel"
	) as WorldMapPanel
	assert_not_null(world_map_panel)
	if world_map_panel == null:
		game_root.free()
		return

	world_map_panel._select_region(&"region_west_shoals")
	assert_true(world_map_panel._confirm_button.disabled)

	assert_true(session.execute_command(
		PlaceBuildingCommand.new(&"building_rudder", Vector2i.ZERO, 0)
	).succeeded)

	assert_false(world_map_panel._confirm_button.disabled)
	game_root.free()


func test_ocean_hud_binds_session_and_shows_current_region() -> void:
	var game_root: Node = preload("res://Scenes/Game/GameRoot.tscn").instantiate()
	Engine.get_main_loop().root.add_child(game_root)
	var session: GameSession = GameSession.new()
	assert_true(session.create_new_game(23), session.get_last_error())
	game_root.bind_session(session)
	var ocean_hud: OceanMapHUD = game_root.get_node(
		"UIRoot/HUDLayer/GameHudLayout/OceanMapHUD"
	) as OceanMapHUD
	assert_not_null(ocean_hud)
	if ocean_hud == null:
		game_root.free()
		return
	assert_false(ocean_hud._region_label.text == GameText.get_text(&"ui.ocean_map.waiting"))
	assert_eq(ocean_hud._region_label.text, GameText.format(&"ui.ocean_map.region", [
		session.get_region_definition(session.get_world_state().current_region_id).get_display_name(),
		0,
		0,
	]))
	game_root.free()
