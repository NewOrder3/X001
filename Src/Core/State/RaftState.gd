class_name RaftState
extends RefCounted

## Runtime raft state. View-independent occupancy rules live in RaftGrid.

var grid: RaftGrid = RaftGrid.new()
var building_instances: Dictionary[StringName, BuildingInstance] = {}


func add_building_instance(instance: BuildingInstance, footprint: Vector2i) -> bool:
	grid.set_building_footprint(instance.building_id, footprint)
	if not grid.place(instance):
		return false
	building_instances[instance.instance_id] = instance
	return true


func remove_building_instance(instance_id: StringName) -> bool:
	if not grid.remove(instance_id):
		return false
	building_instances.erase(instance_id)
	return true


func to_save_data() -> Dictionary:
	var instances: Array[Dictionary] = []
	for instance: BuildingInstance in building_instances.values():
		instances.append(instance.to_save_data())
	return {"grid": grid.to_save_data(), "building_instances": instances}


func load_from_save_data(data: Dictionary) -> bool:
	var raw_grid: Variant = data.get("grid")
	var raw_instances: Variant = data.get("building_instances", [])
	if not raw_grid is Dictionary or not raw_instances is Array or not grid.load_from_save_data(raw_grid):
		return false
	building_instances.clear()
	for raw_instance: Variant in raw_instances:
		if not raw_instance is Dictionary:
			return false
		var instance: BuildingInstance = BuildingInstance.from_save_data(raw_instance)
		if instance.instance_id == &"" or instance.building_id == &"":
			return false
		building_instances[instance.instance_id] = instance
	return true
