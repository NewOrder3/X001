class_name UseFoodCommand
extends GameCommand

var item_id: StringName


func _init(new_item_id: StringName) -> void:
	item_id = new_item_id
