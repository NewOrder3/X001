class_name ProductionInstance
extends RefCounted

## Serializable runtime progress for a facility. ProductionSystem is its only writer.

enum StallReason {
	NONE,
	MANUALLY_STOPPED,
	SUPPLY_DEPLETED,
	MISSING_INPUT,
	OUTPUT_CAPACITY_REACHED,
}

var building_instance_id: StringName
var recipe_id: StringName
var is_enabled: bool = true
var progress_seconds: float = 0.0
var stall_reason: StallReason = StallReason.NONE


func _init(new_building_instance_id: StringName, new_recipe_id: StringName) -> void:
	building_instance_id = new_building_instance_id
	recipe_id = new_recipe_id


func to_save_data() -> Dictionary:
	return {
		"building_instance_id": String(building_instance_id),
		"recipe_id": String(recipe_id),
		"is_enabled": is_enabled,
		"progress_seconds": progress_seconds,
		"stall_reason": int(stall_reason),
	}


static func from_save_data(data: Dictionary) -> ProductionInstance:
	var instance: ProductionInstance = ProductionInstance.new(
		StringName(data.get("building_instance_id", "")),
		StringName(data.get("recipe_id", "")),
	)
	instance.is_enabled = bool(data.get("is_enabled", true))
	instance.progress_seconds = maxf(float(data.get("progress_seconds", 0.0)), 0.0)
	var raw_stall_reason: int = int(data.get("stall_reason", StallReason.NONE))
	instance.stall_reason = clampi(raw_stall_reason, StallReason.NONE, StallReason.OUTPUT_CAPACITY_REACHED) as StallReason
	return instance
