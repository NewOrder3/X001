class_name ExploreRegionCommand
extends GameCommand

## Requests one confirmed voyage to an adjacent discovered-or-reachable region.

var target_region_id: StringName


func _init(new_target_region_id: StringName) -> void:
	target_region_id = new_target_region_id


func get_command_type() -> StringName:
	return &"explore_region"
