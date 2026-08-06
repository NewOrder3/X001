class_name BuildingSystem
extends RefCounted

## Validates placement, then atomically creates a BuildingInstance and spends its cost.

signal building_placed(instance_id: StringName, building_id: StringName, origin: Vector2i)
signal building_upgraded(instance_id: StringName, new_level: int)

const MAX_BUILDING_LEVEL: int = 3

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


func upgrade(state: GameState, command: UpgradeBuildingCommand) -> CommandResult:
	if state == null or command == null or command.building_instance_id == &"":
		return CommandResult.failure(&"invalid_command", GameText.get_text(&"message.building.no_active_state"))
	if not state.raft_state.building_instances.has(command.building_instance_id):
		return CommandResult.failure(&"unknown_building_instance", GameText.get_text(&"message.building.upgrade_unavailable"))

	var instance: BuildingInstance = state.raft_state.building_instances[command.building_instance_id]
	if instance.level >= MAX_BUILDING_LEVEL:
		return CommandResult.failure(&"max_building_level", GameText.get_text(&"message.building.max_level"))
	if _data_registry == null or not _data_registry.has_building(instance.building_id):
		return CommandResult.failure(&"unknown_building", GameText.get_text(&"message.building.unavailable"))

	var definition: BuildingDefinition = _data_registry.get_building(instance.building_id)
	var upgrade_cost: Dictionary[StringName, int] = get_upgrade_cost(instance)
	if _inventory_system == null or not _inventory_system.can_afford(state.inventory_state, upgrade_cost):
		return CommandResult.failure(&"insufficient_resources", GameText.get_text(&"message.building.insufficient_upgrade_resources"))
	if not _inventory_system.spend_cost(state.inventory_state, upgrade_cost):
		return CommandResult.failure(&"insufficient_resources", GameText.get_text(&"message.building.insufficient_upgrade_resources"))

	instance.level += 1
	building_upgraded.emit(instance.instance_id, instance.level)
	return CommandResult.success(GameText.format(&"message.building.upgraded", [definition.get_display_name(), instance.level]))


func get_upgrade_cost(instance: BuildingInstance) -> Dictionary[StringName, int]:
	var cost: Dictionary[StringName, int] = {}
	if instance == null or _data_registry == null or not _data_registry.has_building(instance.building_id):
		return cost
	var definition: BuildingDefinition = _data_registry.get_building(instance.building_id)
	var multiplier: int = instance.level + 1
	for item_id: StringName in definition.build_cost:
		cost[item_id] = definition.build_cost[item_id] * multiplier
	return cost


func _get_next_instance_id(state: GameState, building_id: StringName) -> StringName:
	var name: String = String(building_id).trim_prefix("building_")
	var sequence: int = 1
	var instance_id: StringName = StringName("instance_%s_%d" % [name, sequence])
	while state.raft_state.building_instances.has(instance_id):
		sequence += 1
		instance_id = StringName("instance_%s_%d" % [name, sequence])
	return instance_id
