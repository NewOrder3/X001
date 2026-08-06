class_name StartBattleCommand
extends GameCommand

var boss_id: StringName


func _init(new_boss_id: StringName) -> void:
	boss_id = new_boss_id


func get_command_type() -> StringName:
	return &"start_battle"
