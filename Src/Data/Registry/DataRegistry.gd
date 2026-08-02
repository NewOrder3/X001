class_name DataRegistry
extends RefCounted

## Central read-only access point for static Definitions.

const ITEM_DIRECTORY: String = "res://Data/Items"
const BUILDING_DIRECTORY: String = "res://Data/Buildings"

var _items: Dictionary[StringName, ItemDefinition] = {}
var _buildings: Dictionary[StringName, BuildingDefinition] = {}
var _registered_ids: Dictionary[StringName, bool] = {}
var _last_error: String = ""


func load_all() -> bool:
	_clear()
	var loader: JsonDefinitionLoader = JsonDefinitionLoader.new()

	var item_definitions: Array[ItemDefinition] = loader.load_items(ITEM_DIRECTORY)
	if not loader.get_last_error().is_empty():
		return _fail_load(loader.get_last_error())
	for definition: ItemDefinition in item_definitions:
		if not _register_item(definition):
			return _fail_load(_last_error)

	var building_definitions: Array[BuildingDefinition] = loader.load_buildings(BUILDING_DIRECTORY)
	if not loader.get_last_error().is_empty():
		return _fail_load(loader.get_last_error())
	for definition: BuildingDefinition in building_definitions:
		if not _register_building(definition):
			return _fail_load(_last_error)

	return true


func get_item(id: StringName) -> ItemDefinition:
	if not _items.has(id):
		push_error("DATA: Unknown item Definition ID '%s'." % String(id))
		return null
	return _items[id]


func get_building(id: StringName) -> BuildingDefinition:
	if not _buildings.has(id):
		push_error("DATA: Unknown building Definition ID '%s'." % String(id))
		return null
	return _buildings[id]


func has_definition(id: StringName) -> bool:
	return _registered_ids.has(id)


func get_last_error() -> String:
	return _last_error


func get_item_count() -> int:
	return _items.size()


func get_building_count() -> int:
	return _buildings.size()


func _register_item(definition: ItemDefinition) -> bool:
	if not _register_id(definition.id):
		return false
	_items[definition.id] = definition
	return true


func _register_building(definition: BuildingDefinition) -> bool:
	if not _register_id(definition.id):
		return false
	_buildings[definition.id] = definition
	return true


func _register_id(id: StringName) -> bool:
	if _registered_ids.has(id):
		_set_error("Duplicate Definition ID '%s'." % String(id))
		return false
	_registered_ids[id] = true
	return true


func _clear() -> void:
	_items.clear()
	_buildings.clear()
	_registered_ids.clear()
	_last_error = ""


func _fail_load(message: String) -> bool:
	_items.clear()
	_buildings.clear()
	_registered_ids.clear()
	_last_error = message
	return false


func _set_error(message: String) -> void:
	_last_error = message
