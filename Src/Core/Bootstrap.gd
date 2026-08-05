extends Node

## Minimal application entry point. Scene flow is introduced in F12.
func _enter_tree() -> void:
	GameText.initialize()


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		get_tree().quit()
