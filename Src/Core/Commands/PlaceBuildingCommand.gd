class_name PlaceBuildingCommand
extends GameCommand

## Request data only. BuildingSystem validates and handles it in F15.

var building_id: StringName
var origin: Vector2i
var rotation: int


func _init(new_building_id: StringName, new_origin: Vector2i, new_rotation: int) -> void:
	building_id = new_building_id
	origin = new_origin
	rotation = new_rotation


func get_command_type() -> StringName:
	return &"place_building"
