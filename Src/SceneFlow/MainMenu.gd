class_name MainMenu
extends Control

@onready var _start_button: Button = %StartButton
@onready var _status_label: Label = %StatusLabel


func _ready() -> void:
	_start_button.grab_focus()


func _on_start_button_pressed() -> void:
	var router: SceneRouter = get_node("../../SceneRouter") as SceneRouter
	if router == null:
		_status_label.text = "启动流程不可用。"
		return

	var session: GameSession = GameSession.new()
	var result: CommandResult = session.execute_command(
		CreateNewGameCommand.new(int(Time.get_unix_time_from_system())),
	)
	if not result.succeeded:
		_status_label.text = result.message
		return

	router.enter_game(session)


func _on_quit_button_pressed() -> void:
	get_tree().quit()
