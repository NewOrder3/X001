class_name UIRoot
extends CanvasLayer

signal window_opened(window_id: StringName)
signal window_closed(window_id: StringName)

var _window_stack: Array[StringName] = []
var _open_windows: Dictionary[StringName, Control] = {}

func register_window(window_id: StringName, window: Control) -> void:
	_open_windows[window_id] = window
	window.hide()

func open_window(window_id: StringName, _context: Variant = null) -> bool:
	if _window_stack.has(window_id):
		return false
	if not _open_windows.has(window_id):
		push_error("UI: Unknown window ID '%s'." % String(window_id))
		return false
	var window: Control = _open_windows[window_id]
	window.show()
	_window_stack.append(window_id)
	window_opened.emit(window_id)
	return true

func close_topmost() -> bool:
	if _window_stack.is_empty():
		return false
	var window_id: StringName = _window_stack.pop_back()
	var window: Control = _open_windows[window_id]
	window.hide()
	window_closed.emit(window_id)
	return true


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"cancel") and close_topmost():
		get_viewport().set_input_as_handled()

func show_popup(message: String) -> void:
	var label: Label = get_node_or_null("PopupLayer/PopupLabel") as Label
	if label != null:
		label.text = message
		label.show()

func show_tooltip(message: String) -> void:
	var label: Label = get_node_or_null("TooltipLayer/TooltipLabel") as Label
	if label != null:
		label.text = message
		label.show()
