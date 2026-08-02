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
