class_name RaftBuildView
extends Node2D

## Temporary S1 presentation of the raft grid. It only forwards tile selection to UI.

signal tile_selected(cell: Vector2i)

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
		_draw_diamond(cell, Color("8f6036"), Color("e3b36f"), 3.0)

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
	var body: PackedVector2Array = PackedVector2Array([
		center + Vector2(0.0, -48.0),
		center + Vector2(36.0, -8.0),
		center + Vector2(0.0, 18.0),
		center + Vector2(-36.0, -8.0),
	])
	draw_colored_polygon(body, Color("4e6d62"))
	draw_polyline(body, Color("d4efe3"), 3.0, true)
	draw_circle(center + Vector2(0.0, -19.0), 14.0, Color("7db8c2"))


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
