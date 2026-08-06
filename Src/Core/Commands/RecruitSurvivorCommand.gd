class_name RecruitSurvivorCommand
extends GameCommand

var survivor_id: StringName


func _init(new_survivor_id: StringName) -> void:
	survivor_id = new_survivor_id


func get_command_type() -> StringName:
	return &"recruit_survivor"
