class_name DynamicOceanMap
extends Node2D

## The always-on world view. It visualizes the System-owned hex world and turns
## direct map clicks into ExploreRegionCommand requests.

signal voyage_status_changed(message: String)
signal hovered_region_changed(region_name: String)

const DISPLAY_RADIUS: int = 4
const BASE_TILE_RADIUS: float = 150.0
const VERTICAL_PROJECTION: float = 0.56
const TRAVEL_DURATION: float = 0.9
const DRAG_THRESHOLD: float = 10.0
const SHIP_TEXTURE: Texture2D = preload("res://Assets/Art/Ship/player_ship_isometric.png")
const RESOURCE_MARKER_TEXTURE: Texture2D = preload("res://Assets/Art/Map/salvage_marker_isometric.png")

var _session: GameSession = null
var _wave_time: float = 0.0
var _pan_offset: Vector2 = Vector2.ZERO
var _zoom: float = 1.0
var _is_navigation_mode: bool = true
var _is_pointer_down: bool = false
var _is_dragging: bool = false
var _pointer_down_position: Vector2 = Vector2.ZERO
var _hovered_region_id: StringName = &""
var _visual_origin_coordinate: Vector2i = Vector2i.ZERO
var _travel_from_coordinate: Vector2i = Vector2i.ZERO
var _travel_to_coordinate: Vector2i = Vector2i.ZERO
var _travel_elapsed: float = 0.0
var _is_traveling: bool = false


func _ready() -> void:
	get_viewport().size_changed.connect(queue_redraw)


func bind_session(session: GameSession) -> void:
	_session = session
	if _session != null:
		var exploration_system: ExplorationSystem = _session.get_exploration_system()
		if not exploration_system.exploration_completed.is_connected(_on_exploration_completed):
			exploration_system.exploration_completed.connect(_on_exploration_completed)
		if _session.has_active_state():
			var current: RegionDefinition = _session.get_region_definition(_session.get_world_state().current_region_id)
			if current != null:
				_visual_origin_coordinate = current.coordinate
	queue_redraw()


func set_navigation_mode(is_enabled: bool) -> void:
	_is_navigation_mode = is_enabled
	_is_pointer_down = false
	_is_dragging = false
	if not is_enabled:
		_set_hovered_region(&"")


func _unhandled_input(event: InputEvent) -> void:
	if not _is_navigation_mode or _session == null or not _session.has_active_state() or _is_traveling:
		return
	if event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_button.pressed:
			_zoom = minf(_zoom + 0.08, 1.25)
			queue_redraw()
			get_viewport().set_input_as_handled()
			return
		if mouse_button.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_button.pressed:
			_zoom = maxf(_zoom - 0.08, 0.72)
			queue_redraw()
			get_viewport().set_input_as_handled()
			return
		if mouse_button.button_index == MOUSE_BUTTON_LEFT:
			if mouse_button.pressed:
				_is_pointer_down = true
				_is_dragging = false
				_pointer_down_position = mouse_button.position
			else:
				if _is_pointer_down and not _is_dragging:
					_try_sail_to_position(mouse_button.position)
				_is_pointer_down = false
				_is_dragging = false
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseMotion:
		var mouse_motion: InputEventMouseMotion = event as InputEventMouseMotion
		if _is_pointer_down:
			if mouse_motion.position.distance_to(_pointer_down_position) >= DRAG_THRESHOLD:
				_is_dragging = true
			if _is_dragging:
				_pan_offset += mouse_motion.relative
				queue_redraw()
				get_viewport().set_input_as_handled()
				return
		_update_hover(mouse_motion.position)
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if touch.pressed:
			_is_pointer_down = true
			_is_dragging = false
			_pointer_down_position = touch.position
		else:
			if _is_pointer_down and not _is_dragging:
				_try_sail_to_position(touch.position)
			_is_pointer_down = false
			_is_dragging = false
		get_viewport().set_input_as_handled()
	if event is InputEventScreenDrag and _is_pointer_down:
		var drag: InputEventScreenDrag = event as InputEventScreenDrag
		if drag.position.distance_to(_pointer_down_position) >= DRAG_THRESHOLD:
			_is_dragging = true
		if _is_dragging:
			_pan_offset += drag.relative
			queue_redraw()
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_wave_time += delta
	if _is_traveling:
		_travel_elapsed += delta
		if _travel_elapsed >= TRAVEL_DURATION:
			_is_traveling = false
			_visual_origin_coordinate = _travel_to_coordinate
			_pan_offset = Vector2.ZERO
	queue_redraw()


func _on_exploration_completed(_result: ExplorationResult) -> void:
	queue_redraw()


func _draw() -> void:
	if _session == null or not _session.has_active_state():
		return
	var world_state: WorldState = _session.get_world_state()
	var current_region: RegionDefinition = _session.get_region_definition(world_state.current_region_id)
	if current_region == null:
		return
	if not _is_traveling:
		_visual_origin_coordinate = current_region.coordinate
	var center: Vector2 = _get_map_center()
	var reachable_by_coordinate: Dictionary[Vector2i, RegionDefinition] = {}
	for region: RegionDefinition in _session.get_reachable_regions():
		reachable_by_coordinate[region.coordinate] = region

	for q_offset: int in range(-DISPLAY_RADIUS, DISPLAY_RADIUS + 1):
		for r_offset: int in range(-DISPLAY_RADIUS, DISPLAY_RADIUS + 1):
			var offset: Vector2i = Vector2i(q_offset, r_offset)
			if HexGrid.distance_to_coord(Vector2i.ZERO, offset) > DISPLAY_RADIUS:
				continue
			var coordinate: Vector2i = _visual_origin_coordinate + offset
			_draw_sea_cell(center + _hex_offset(offset), coordinate, world_state, reachable_by_coordinate, current_region.coordinate)

	_draw_route(center, reachable_by_coordinate, current_region.coordinate)
	_draw_ship(center, current_region.coordinate)


func _draw_sea_cell(
	center: Vector2,
	coordinate: Vector2i,
	world_state: WorldState,
	reachable: Dictionary[Vector2i, RegionDefinition],
	current_coordinate: Vector2i,
) -> void:
	var polygon: PackedVector2Array = _get_hex_polygon(center)
	var region: RegionDefinition = _get_region_at_coordinate(coordinate, reachable)
	var is_current: bool = coordinate == current_coordinate
	var is_discovered: bool = region != null and world_state.is_discovered(region.id)
	var is_reachable: bool = reachable.has(coordinate)
	var is_hovered: bool = region != null and region.id == _hovered_region_id
	var fill: Color = Color.TRANSPARENT
	var outline: Color = Color.TRANSPARENT
	if is_discovered:
		fill = Color(0.04, 0.34, 0.40, 0.025)
	if is_reachable:
		fill = Color(0.08, 0.54, 0.62, 0.08)
		outline = Color(0.88, 0.96, 0.73, 0.28)
	if is_hovered:
		fill = Color(0.95, 0.70, 0.25, 0.25)
		outline = Color(1.0, 0.89, 0.55, 0.95)
	if is_current:
		fill = Color.TRANSPARENT
		outline = Color.TRANSPARENT
	draw_colored_polygon(polygon, fill)
	for index: int in range(polygon.size()):
		draw_line(polygon[index], polygon[(index + 1) % polygon.size()], outline, 2.0 if not is_hovered else 4.0, true)
	if is_reachable and not is_current and region != null:
		_draw_region_marker(center, region)


func _draw_region_marker(center: Vector2, region: RegionDefinition) -> void:
	var marker_size: Vector2 = Vector2.ONE * 142.0 * _zoom
	var bob: float = sin(_wave_time * 1.8 + float(region.coordinate.x * 3 + region.coordinate.y)) * 4.0
	var rect: Rect2 = Rect2(center - marker_size * 0.5 + Vector2(0.0, bob - 12.0 * _zoom), marker_size)
	draw_set_transform(center + Vector2(0.0, 22.0 * _zoom), 0.0, Vector2(1.0, 0.42))
	draw_circle(Vector2.ZERO, 42.0 * _zoom, Color(0.01, 0.08, 0.12, 0.26))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_texture_rect(RESOURCE_MARKER_TEXTURE, rect, false)


func _draw_route(center: Vector2, reachable: Dictionary[Vector2i, RegionDefinition], current_coordinate: Vector2i) -> void:
	if _hovered_region_id == &"":
		return
	for coordinate: Vector2i in reachable:
		if reachable[coordinate].id != _hovered_region_id:
			continue
		var start: Vector2 = center + _hex_offset(current_coordinate - _visual_origin_coordinate)
		var target: Vector2 = center + _hex_offset(coordinate - _visual_origin_coordinate)
		draw_dashed_line(start, target, Color(1.0, 0.88, 0.48, 0.88), 4.0, 14.0, true)
		draw_circle(target, 11.0, Color(1.0, 0.80, 0.34, 0.92))
		return


func _draw_ship(center: Vector2, current_coordinate: Vector2i) -> void:
	var ship_position: Vector2 = center + _hex_offset(current_coordinate - _visual_origin_coordinate)
	var horizontal_flip: float = 1.0
	if _is_traveling:
		var progress: float = smoothstep(0.0, 1.0, clampf(_travel_elapsed / TRAVEL_DURATION, 0.0, 1.0))
		var from_position: Vector2 = center + _hex_offset(_travel_from_coordinate - _visual_origin_coordinate)
		var to_position: Vector2 = center + _hex_offset(_travel_to_coordinate - _visual_origin_coordinate)
		ship_position = from_position.lerp(to_position, progress)
		var direction: Vector2 = to_position - from_position
		horizontal_flip = -1.0 if direction.x < 0.0 else 1.0
		_draw_wake(ship_position, -direction.normalized())
	var ship_size: Vector2 = Vector2.ONE * 276.0 * _zoom
	var bob: float = sin(_wave_time * 2.1) * 4.0
	draw_set_transform(ship_position + Vector2(0.0, bob + 30.0 * _zoom), 0.0, Vector2(1.0, 0.38))
	draw_circle(Vector2.ZERO, 76.0 * _zoom, Color(0.015, 0.07, 0.10, 0.30))
	draw_set_transform(ship_position + Vector2(0.0, bob - 34.0 * _zoom), 0.0, Vector2(horizontal_flip, 1.0))
	draw_texture_rect(SHIP_TEXTURE, Rect2(-ship_size * 0.5, ship_size), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_wake(ship_position: Vector2, wake_direction: Vector2) -> void:
	var side: Vector2 = wake_direction.orthogonal()
	for index: int in range(3):
		var distance: float = 46.0 + float(index) * 20.0
		var alpha: float = 0.34 - float(index) * 0.08
		var wake_center: Vector2 = ship_position + wake_direction * distance
		draw_line(wake_center - side * (18.0 + index * 5.0), wake_center + side * (18.0 + index * 5.0), Color(0.86, 0.98, 0.96, alpha), 4.0, true)


func _try_sail_to_position(screen_position: Vector2) -> void:
	var target: RegionDefinition = _get_reachable_region_at(screen_position)
	if target == null:
		return
	var current: RegionDefinition = _session.get_region_definition(_session.get_world_state().current_region_id)
	if current == null:
		return
	var result: CommandResult = _session.execute_command(ExploreRegionCommand.new(target.id))
	voyage_status_changed.emit(result.message)
	if not result.succeeded:
		return
	_travel_from_coordinate = current.coordinate
	_travel_to_coordinate = target.coordinate
	_visual_origin_coordinate = current.coordinate
	_travel_elapsed = 0.0
	_is_traveling = true
	_set_hovered_region(&"")


func _get_reachable_region_at(screen_position: Vector2) -> RegionDefinition:
	var best_region: RegionDefinition = null
	var best_distance: float = BASE_TILE_RADIUS * _zoom * 0.82
	for region: RegionDefinition in _session.get_reachable_regions():
		var region_position: Vector2 = _get_map_center() + _hex_offset(region.coordinate - _visual_origin_coordinate)
		var distance: float = screen_position.distance_to(region_position)
		if distance < best_distance:
			best_distance = distance
			best_region = region
	return best_region


func _update_hover(screen_position: Vector2) -> void:
	var region: RegionDefinition = _get_reachable_region_at(screen_position)
	_set_hovered_region(region.id if region != null else &"")


func _set_hovered_region(region_id: StringName) -> void:
	if _hovered_region_id == region_id:
		return
	_hovered_region_id = region_id
	var name: String = ""
	if region_id != &"":
		var region: RegionDefinition = _session.get_region_definition(region_id)
		name = region.get_display_name() if region != null else ""
	hovered_region_changed.emit(name)
	queue_redraw()


func _get_region_at_coordinate(coordinate: Vector2i, reachable: Dictionary[Vector2i, RegionDefinition]) -> RegionDefinition:
	if reachable.has(coordinate):
		return reachable[coordinate]
	var current: RegionDefinition = _session.get_region_definition(_session.get_world_state().current_region_id)
	if current != null and current.coordinate == coordinate:
		return current
	return _session.get_region_definition(_generated_region_id(coordinate))


func _get_map_center() -> Vector2:
	return get_viewport_rect().size * 0.5 + Vector2(0.0, 18.0) + _pan_offset


func _hex_offset(coordinate: Vector2i) -> Vector2:
	var radius: float = BASE_TILE_RADIUS * _zoom
	var width: float = sqrt(3.0) * radius
	return Vector2(
		width * (float(coordinate.x) + float(coordinate.y) * 0.5),
		radius * 1.5 * float(coordinate.y) * VERTICAL_PROJECTION,
	)


func _get_hex_polygon(center: Vector2) -> PackedVector2Array:
	var polygon: PackedVector2Array = PackedVector2Array()
	var radius: float = BASE_TILE_RADIUS * _zoom
	for index: int in range(6):
		var angle: float = deg_to_rad(60.0 * float(index) - 30.0)
		polygon.append(center + Vector2(cos(angle) * radius, sin(angle) * radius * VERTICAL_PROJECTION))
	return polygon


func _generated_region_id(coordinate: Vector2i) -> StringName:
	return StringName("region_open_sea_q%s_r%s" % [_encode_coordinate(coordinate.x), _encode_coordinate(coordinate.y)])


func _encode_coordinate(value: int) -> String:
	return "neg_%d" % abs(value) if value < 0 else str(value)
