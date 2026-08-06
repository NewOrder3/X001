class_name MainMenu
extends Control

@onready var _start_button: Button = %StartButton
@onready var _continue_button: Button = %ContinueButton
@onready var _status_label: Label = %StatusLabel


func _ready() -> void:
	_start_button.grab_focus()
	_continue_button.disabled = not SaveService.new().has_save(&"main")


func _on_start_button_pressed() -> void:
	var router: SceneRouter = get_node("../../SceneRouter") as SceneRouter
	if router == null:
		_status_label.text = GameText.get_text(&"ui.main_menu.start_unavailable")
		return

	var session: GameSession = GameSession.new()
	var result: CommandResult = session.execute_command(
		CreateNewGameCommand.new(int(Time.get_unix_time_from_system())),
	)
	if not result.succeeded:
		_status_label.text = result.message
		return

	router.enter_game(session)


func _on_continue_button_pressed() -> void:
	var router: SceneRouter = get_node("../../SceneRouter") as SceneRouter
	if router == null:
		_status_label.text = GameText.get_text(&"ui.main_menu.start_unavailable")
		return
	var save_service: SaveService = SaveService.new()
	var loaded_state: GameState = save_service.load_game(&"main")
	if loaded_state == null:
		_status_label.text = GameText.get_text(&"message.save.load_failed")
		return
	var session: GameSession = GameSession.new()
	if not session.load_state_at(loaded_state, int(Time.get_unix_time_from_system())):
		_status_label.text = session.get_last_error()
		return
	router.enter_game(session)


func _on_quit_button_pressed() -> void:
	get_tree().quit()
