class_name RaftBuildView
extends Node2D

## Temporary S1 presentation of the raft grid. It only forwards tile selection to UI.

signal tile_selected(cell: Vector2i)

const DECK_TEXTURE: Texture2D = preload("res://Assets/Temp/ship/ship_tile_deck_wooden.png")
const CAMPFIRE_TEXTURE: Texture2D = preload("res://Assets/Temp/facility/facility_build_campfire.png")
const RAIN_COLLECTOR_TEXTURE: Texture2D = preload("res://Assets/Temp/facility/facility_build_rain_collector.png")
const REPAIR_STATION_TEXTURE: Texture2D = preload("res://Assets/Temp/facility/facility_build_repair_station.png")
const WATER_TANK_TEXTURE: Texture2D = preload("res://Assets/Temp/facility/facility_build_water_tank.png")
const RUDDER_TEXTURE: Texture2D = preload("res://Assets/Temp/ship/ship_rudder.png")

var _session: GameSession = null
var _selected_building_id: StringName = &""
var _preview_cell: Vector2i = Vector2i.ZERO
var _has_preview: bool = false


func bind_session(session: GameSession) -> void:
	_session = session
	queue_redraw()


func select_building(building_id: StringName) -> void:
	_selected_building_id = building_id
	_has_preview = false
	queue_redraw()


func set_preview_cell(cell: Vector2i) -> void:
	if _selected_building_id == &"":
		return
	_preview_cell = cell
	_has_preview = true
	queue_redraw()


func clear_preview() -> void:
	_has_preview = false
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if _session == null or _selected_building_id == &"":
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_select_tile_at_global_position(event.position)
		return
	if event is InputEventMouseMotion:
		var cell: Vector2i = GridMath.world_to_grid(to_local(event.position))
		set_preview_cell(cell)
		return
	if event is InputEventScreenTouch and event.pressed:
		_select_tile_at_global_position(event.position)


func _select_tile_at_global_position(global_position: Vector2) -> void:
	var cell: Vector2i = GridMath.world_to_grid(to_local(global_position))
	set_preview_cell(cell)
	tile_selected.emit(cell)
	if is_inside_tree():
		get_viewport().set_input_as_handled()


func _draw() -> void:
	if _session == null or not _session.has_active_state():
		return
	var raft_state: RaftState = _session.get_raft_state()
	if raft_state == null:
		return

	for cell: Vector2i in raft_state.grid.get_deck_cells():
		_draw_deck_tile(cell)

	for instance: BuildingInstance in raft_state.building_instances.values():
		_draw_building(instance)

	if _has_preview:
		_draw_preview(raft_state)


func _draw_diamond(cell: Vector2i, fill_color: Color, outline_color: Color, outline_width: float) -> void:
	var polygon: PackedVector2Array = GridMath.get_cell_polygon(cell)
	draw_colored_polygon(polygon, fill_color)
	for index: int in range(polygon.size()):
		draw_line(polygon[index], polygon[(index + 1) % polygon.size()], outline_color, outline_width, true)


func _draw_building(instance: BuildingInstance) -> void:
	var center: Vector2 = GridMath.grid_to_world(instance.grid_position)
	var texture: Texture2D = _get_building_texture(instance.building_id)
	if texture == null:
		return
	var size: Vector2 = Vector2(124.0, 124.0)
	draw_texture_rect(texture, Rect2(center - size * 0.5, size), false)
	var badge_center: Vector2 = center + Vector2(0.0, 42.0)
	draw_circle(badge_center, 22.0, Color(0.04, 0.12, 0.14, 0.88))
	draw_arc(badge_center, 22.0, 0.0, TAU, 20, Color(0.96, 0.73, 0.32, 0.90), 2.0, true)
	draw_string(
		ThemeDB.fallback_font,
		badge_center + Vector2(-20.0, 7.0),
		GameText.get_text(&"ui.build.level_badge") % instance.level,
		HORIZONTAL_ALIGNMENT_CENTER,
		40.0,
		16,
		Color(1.0, 0.94, 0.78, 1.0),
	)


func _draw_deck_tile(cell: Vector2i) -> void:
	var center: Vector2 = GridMath.grid_to_world(cell)
	var size: Vector2 = Vector2(128.0, 96.0)
	draw_texture_rect(DECK_TEXTURE, Rect2(center - size * 0.5, size), false)


func _get_building_texture(building_id: StringName) -> Texture2D:
	match building_id:
		&"building_campfire":
			return CAMPFIRE_TEXTURE
		&"building_rain_collector":
			return RAIN_COLLECTOR_TEXTURE
		&"building_repair_station":
			return REPAIR_STATION_TEXTURE
		&"building_water_tank":
			return WATER_TANK_TEXTURE
		&"building_rudder":
			return RUDDER_TEXTURE
	return null


func _draw_preview(raft_state: RaftState) -> void:
	var definition: BuildingDefinition = _session.get_building_definition(_selected_building_id)
	if definition == null:
		return
	var can_place: bool = raft_state.grid.can_place(definition.footprint, _preview_cell, 0)
	var fill_color: Color = Color(0.31, 0.85, 0.59, 0.45) if can_place else Color(0.92, 0.29, 0.24, 0.45)
	var outline_color: Color = Color("8cf0af") if can_place else Color("ff8175")
	for cell: Vector2i in _get_footprint_cells(definition.footprint, _preview_cell):
		_draw_diamond(cell, fill_color, outline_color, 4.0)


func _get_footprint_cells(footprint: Vector2i, origin: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for x: int in range(footprint.x):
		for y: int in range(footprint.y):
			cells.append(origin + Vector2i(x, y))
	return cells
