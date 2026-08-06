class_name BattleActionCommand
extends GameCommand

var actor_id: StringName
var use_skill: bool


func _init(new_actor_id: StringName, new_use_skill: bool) -> void:
	actor_id = new_actor_id
	use_skill = new_use_skill


func get_command_type() -> StringName:
	return &"battle_action"
