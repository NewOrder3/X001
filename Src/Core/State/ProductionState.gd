class_name ProductionState
extends RefCounted

## Serializable facility operation state. ProductionSystem owns all mutations.

var instances: Dictionary[StringName, ProductionInstance] = {}


func to_save_data() -> Dictionary:
	var saved_instances: Array[Dictionary] = []
	for instance_id: StringName in instances:
		saved_instances.append(instances[instance_id].to_save_data())
	return {"instances": saved_instances}


func load_from_save_data(data: Dictionary) -> bool:
	var raw_instances: Variant = data.get("instances", [])
	if not raw_instances is Array:
		return false
	instances.clear()
	for raw_instance: Variant in raw_instances:
		if not raw_instance is Dictionary:
			return false
		var instance: ProductionInstance = ProductionInstance.from_save_data(raw_instance)
		if instance.building_instance_id == &"" or instances.has(instance.building_instance_id):
			return false
		instances[instance.building_instance_id] = instance
	return true
