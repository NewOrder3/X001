class_name GatherResourcesCommand
extends GameCommand

var item_id: StringName
var amount: int


func _init(new_item_id: StringName, new_amount: int) -> void:
	item_id = new_item_id
	amount = new_amount


func get_command_type() -> StringName:
	return &"gather_resources"
