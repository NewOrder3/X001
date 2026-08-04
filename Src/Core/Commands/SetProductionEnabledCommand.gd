class_name SetProductionEnabledCommand
extends GameCommand

var building_instance_id: StringName
var is_enabled: bool


func _init(new_building_instance_id: StringName, new_is_enabled: bool) -> void:
	building_instance_id = new_building_instance_id
	is_enabled = new_is_enabled
