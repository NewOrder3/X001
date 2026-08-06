class_name SetLineupCommand
extends GameCommand

var lineup_ids: Array[StringName]


func _init(new_lineup_ids: Array[StringName]) -> void:
	lineup_ids = new_lineup_ids.duplicate()


func get_command_type() -> StringName:
	return &"set_lineup"
