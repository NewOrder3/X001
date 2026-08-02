class_name BuildingInstance
extends RefCounted

## Serializable runtime state for one placed building; it never owns a View node.

var instance_id: StringName
var building_id: StringName
var grid_position: Vector2i
var rotation: int
var level: int


func _init(
	new_instance_id: StringName,
	new_building_id: StringName,
	new_grid_position: Vector2i,
	new_rotation: int = 0,
	new_level: int = 1,
) -> void:
	instance_id = new_instance_id
	building_id = new_building_id
	grid_position = new_grid_position
	rotation = new_rotation
	level = new_level


func to_save_data() -> Dictionary:
	return {
		"instance_id": String(instance_id),
		"building_id": String(building_id),
		"x": grid_position.x,
		"y": grid_position.y,
		"rotation": rotation,
		"level": level,
	}


static func from_save_data(data: Dictionary) -> BuildingInstance:
	return BuildingInstance.new(
		StringName(data.get("instance_id", "")),
		StringName(data.get("building_id", "")),
		Vector2i(int(data.get("x", 0)), int(data.get("y", 0))),
		int(data.get("rotation", 0)),
		int(data.get("level", 1)),
	)
