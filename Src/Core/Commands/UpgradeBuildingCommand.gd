class_name UpgradeBuildingCommand
extends GameCommand

## Requests an upgrade for one placed facility. BuildingSystem owns validation and cost.

var building_instance_id: StringName


func _init(new_building_instance_id: StringName) -> void:
	building_instance_id = new_building_instance_id


func get_command_type() -> StringName:
	return &"upgrade_building"
