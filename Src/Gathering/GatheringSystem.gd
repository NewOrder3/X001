class_name GatheringSystem
extends RefCounted

## Minimal deterministic resource source for the S3 vertical slice.

signal resource_gathered(item_id: StringName, amount: int)

var _data_registry: DataRegistry
var _inventory_system: InventorySystem


func _init(data_registry: DataRegistry, inventory_system: InventorySystem) -> void:
	_data_registry = data_registry
	_inventory_system = inventory_system


func execute(state: GameState, command: GatherResourcesCommand) -> CommandResult:
	if state == null or command == null or command.amount <= 0:
		return CommandResult.failure(&"invalid_gather_request", GameText.get_text(&"message.gather.invalid_request"))
	if _data_registry == null or not _data_registry.has_item(command.item_id):
		return CommandResult.failure(&"unknown_item", GameText.get_text(&"message.gather.unavailable"))
	var capacity: int = _inventory_system.get_capacity(state, command.item_id)
	if not _inventory_system.add(state.inventory_state, command.item_id, command.amount, capacity):
		return CommandResult.failure(&"inventory_full", GameText.get_text(&"message.gather.inventory_full"))
	resource_gathered.emit(command.item_id, command.amount)
	var definition: ItemDefinition = _data_registry.get_item(command.item_id)
	return CommandResult.success(GameText.format(&"message.gather.collected", [command.amount, definition.get_display_name()]))
