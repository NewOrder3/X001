class_name InputService
extends Node

signal pan_requested(delta: Vector2)
signal zoom_requested(amount: float)
signal world_tap_requested(position: Vector2)
signal world_long_press_requested(position: Vector2)

const LONG_PRESS_SECONDS: float = 0.5
var _pointer_down_time_msec: int = 0
var _is_panning: bool = false
var _touch_positions: Dictionary[int, Vector2] = {}
var _last_pinch_distance: float = 0.0

func get_action_state(action: StringName) -> bool:
	return Input.is_action_pressed(action)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			_is_panning = true
			pan_requested.emit(event.relative)
	elif event is InputEventScreenDrag:
		_is_panning = true
		pan_requested.emit(event.relative)
		_process_touch_pinch(event)
	elif event is InputEventScreenTouch:
		_handle_screen_touch(event)

func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		zoom_requested.emit(1.0)
		return
	if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		zoom_requested.emit(-1.0)
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.pressed:
		_touch_positions[event.index] = event.position
		_pointer_down_time_msec = Time.get_ticks_msec()
		_is_panning = false
		return
	_touch_positions.erase(event.index)
	var held_seconds: float = float(Time.get_ticks_msec() - _pointer_down_time_msec) / 1000.0
	if _is_panning:
		_is_panning = false
	elif held_seconds >= LONG_PRESS_SECONDS:
		world_long_press_requested.emit(event.position)
	else:
		world_tap_requested.emit(event.position)

func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		_pointer_down_time_msec = Time.get_ticks_msec()
		_is_panning = false
		return
	var held_seconds: float = float(Time.get_ticks_msec() - _pointer_down_time_msec) / 1000.0
	if not _is_panning and held_seconds >= LONG_PRESS_SECONDS:
		world_long_press_requested.emit(event.position)
	elif not _is_panning:
		world_tap_requested.emit(event.position)
	_is_panning = false


func _process_touch_pinch(event: InputEventScreenDrag) -> void:
	_touch_positions[event.index] = event.position
	if _touch_positions.size() != 2:
		_last_pinch_distance = 0.0
		return
	var positions: Array[Vector2] = []
	for position: Vector2 in _touch_positions.values():
		positions.append(position)
	var distance: float = positions[0].distance_to(positions[1])
	if _last_pinch_distance > 0.0:
		zoom_requested.emit((distance - _last_pinch_distance) / 100.0)
	_last_pinch_distance = distance
