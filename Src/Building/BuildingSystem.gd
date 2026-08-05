class_name BuildingSystem
extends RefCounted

## Validates placement, then atomically creates a BuildingInstance and spends its cost.

signal building_placed(instance_id: StringName, building_id: StringName, origin: Vector2i)

var _data_registry: DataRegistry
var _inventory_system: InventorySystem


func _init(new_data_registry: DataRegistry, new_inventory_system: InventorySystem) -> void:
	_data_registry = new_data_registry
	_inventory_system = new_inventory_system


func execute(state: GameState, command: PlaceBuildingCommand) -> CommandResult:
	if state == null or command == null:
		return CommandResult.failure(&"invalid_command", GameText.get_text(&"message.building.no_active_state"))
	if command.rotation < 0 or command.rotation > 3:
		return CommandResult.failure(&"invalid_rotation", GameText.get_text(&"message.building.invalid_rotation"))
	if _data_registry == null or not _data_registry.has_building(command.building_id):
		return CommandResult.failure(&"unknown_building", GameText.get_text(&"message.building.unavailable"))

	var definition: BuildingDefinition = _data_registry.get_building(command.building_id)
	if not state.raft_state.grid.can_place(definition.footprint, command.origin, command.rotation):
		return CommandResult.failure(&"invalid_placement", GameText.get_text(&"message.building.invalid_placement"))
	if _inventory_system == null or not _inventory_system.can_afford(state.inventory_state, definition.build_cost):
		return CommandResult.failure(&"insufficient_resources", GameText.get_text(&"message.building.insufficient_resources"))

	var instance: BuildingInstance = BuildingInstance.new(
		_get_next_instance_id(state, command.building_id),
		command.building_id,
		command.origin,
		command.rotation,
	)
	if not state.raft_state.add_building_instance(instance, definition.footprint):
		return CommandResult.failure(&"invalid_placement", GameText.get_text(&"message.building.invalid_placement"))
	if not _inventory_system.spend_cost(state.inventory_state, definition.build_cost):
		state.raft_state.remove_building_instance(instance.instance_id)
		return CommandResult.failure(&"insufficient_resources", GameText.get_text(&"message.building.insufficient_resources"))

	building_placed.emit(instance.instance_id, instance.building_id, instance.grid_position)
	return CommandResult.success(GameText.format(&"message.building.built", [definition.get_display_name()]))


func _get_next_instance_id(state: GameState, building_id: StringName) -> StringName:
	var name: String = String(building_id).trim_prefix("building_")
	var sequence: int = 1
	var instance_id: StringName = StringName("instance_%s_%d" % [name, sequence])
	while state.raft_state.building_instances.has(instance_id):
		sequence += 1
		instance_id = StringName("instance_%s_%d" % [name, sequence])
	return instance_id
