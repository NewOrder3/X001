class_name CreateNewGameCommand
extends GameCommand

var world_seed: int


func _init(new_world_seed: int) -> void:
	world_seed = new_world_seed


func get_command_type() -> StringName:
	return &"create_new_game"
