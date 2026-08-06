class_name GameMenuPanel
extends PanelContainer

## In-game pause menu: save current progress or return to the main menu.

signal close_requested
signal return_to_main_menu_requested

const SAVE_SLOT_ID: StringName = &"main"

@onready var _status_label: Label = %MenuStatusLabel
@onready var _save_button: Button = %SaveButton
@onready var _return_button: Button = %ReturnMainButton
@onready var _close_button: Button = %CloseMenuButton

var _session: GameSession = null
var _save_service: SaveService = SaveService.new()


func _ready() -> void:
	_save_button.pressed.connect(_save_game)
	_return_button.pressed.connect(return_to_main_menu_requested.emit)
	_close_button.pressed.connect(close_requested.emit)
	refresh()


func bind_session(session: GameSession) -> void:
	_session = session
	refresh()


func refresh() -> void:
	if not is_instance_valid(_save_button):
		return
	_save_button.disabled = _session == null or not _session.has_active_state()


func _save_game() -> void:
	if _session == null or not _session.has_active_state():
		_status_label.text = GameText.get_text(&"ui.menu.no_session")
		return
	_save_service.set_active_state(_session.get_state())
	if _save_service.save_game(SAVE_SLOT_ID):
		_status_label.text = GameText.get_text(&"ui.menu.saved")
	else:
		_status_label.text = GameText.get_text(&"ui.menu.save_failed")
