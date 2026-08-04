class_name DataRegistry
extends RefCounted

## Central read-only access point for static Definitions.

const ITEM_DIRECTORY: String = "res://Data/Items"
const BUILDING_DIRECTORY: String = "res://Data/Buildings"
const SURVIVAL_DIRECTORY: String = "res://Data/Survival"
const RECIPE_DIRECTORY: String = "res://Data/Recipes"

var _item_directory: String
var _building_directory: String
var _survival_directory: String
var _recipe_directory: String
var _items: Dictionary[StringName, ItemDefinition] = {}
var _buildings: Dictionary[StringName, BuildingDefinition] = {}
var _survival_configs: Dictionary[StringName, SurvivalConfigDefinition] = {}
var _recipes: Dictionary[StringName, RecipeDefinition] = {}
var _registered_ids: Dictionary[StringName, bool] = {}
var _last_error: String = ""


func _init(
	new_item_directory: String = ITEM_DIRECTORY,
	new_building_directory: String = BUILDING_DIRECTORY,
	new_survival_directory: String = SURVIVAL_DIRECTORY,
	new_recipe_directory: String = "",
) -> void:
	_item_directory = new_item_directory
	_building_directory = new_building_directory
	_survival_directory = new_survival_directory
	_recipe_directory = RECIPE_DIRECTORY if new_recipe_directory.is_empty() and new_item_directory == ITEM_DIRECTORY and new_building_directory == BUILDING_DIRECTORY else new_recipe_directory


func load_all() -> bool:
	_clear()
	var loader: JsonDefinitionLoader = JsonDefinitionLoader.new()

	var item_definitions: Array[ItemDefinition] = loader.load_items(_item_directory)
	if not loader.get_last_error().is_empty():
		return _fail_load(loader.get_last_error())
	for definition: ItemDefinition in item_definitions:
		if not _register_item(definition):
			return _fail_load(_last_error)

	var building_definitions: Array[BuildingDefinition] = loader.load_buildings(_building_directory)
	if not loader.get_last_error().is_empty():
		return _fail_load(loader.get_last_error())
	for definition: BuildingDefinition in building_definitions:
		if not _register_building(definition):
			return _fail_load(_last_error)

	var survival_definitions: Array[SurvivalConfigDefinition] = loader.load_survival_configs(_survival_directory)
	if not loader.get_last_error().is_empty():
		return _fail_load(loader.get_last_error())
	for definition: SurvivalConfigDefinition in survival_definitions:
		if not _register_survival_config(definition):
			return _fail_load(_last_error)
	if not _recipe_directory.is_empty():
		var recipe_definitions: Array[RecipeDefinition] = loader.load_recipes(_recipe_directory)
		if not loader.get_last_error().is_empty():
			return _fail_load(loader.get_last_error())
		for definition: RecipeDefinition in recipe_definitions:
			if not _register_recipe(definition):
				return _fail_load(_last_error)
	if not _validate_building_item_references():
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


func get_survival_config(id: StringName) -> SurvivalConfigDefinition:
	if not _survival_configs.has(id):
		push_error("DATA: Unknown survival Definition ID '%s'." % String(id))
		return null
	return _survival_configs[id]


func get_recipe(id: StringName) -> RecipeDefinition:
	if not _recipes.has(id):
		push_error("DATA: Unknown recipe Definition ID '%s'." % String(id))
		return null
	return _recipes[id]


func has_definition(id: StringName) -> bool:
	return _registered_ids.has(id)


func has_item(id: StringName) -> bool:
	return _items.has(id)


func has_building(id: StringName) -> bool:
	return _buildings.has(id)


func has_survival_config(id: StringName) -> bool:
	return _survival_configs.has(id)


func has_recipe(id: StringName) -> bool:
	return _recipes.has(id)


func get_last_error() -> String:
	return _last_error


func get_item_count() -> int:
	return _items.size()


func get_building_count() -> int:
	return _buildings.size()


func get_survival_config_count() -> int:
	return _survival_configs.size()


func get_recipe_count() -> int:
	return _recipes.size()


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


func _register_survival_config(definition: SurvivalConfigDefinition) -> bool:
	if not _register_id(definition.id):
		return false
	_survival_configs[definition.id] = definition
	return true


func _register_recipe(definition: RecipeDefinition) -> bool:
	if not _register_id(definition.id):
		return false
	_recipes[definition.id] = definition
	return true


func _register_id(id: StringName) -> bool:
	if _registered_ids.has(id):
		_set_error("Duplicate Definition ID '%s'." % String(id))
		return false
	_registered_ids[id] = true
	return true


func _validate_building_item_references() -> bool:
	for building: BuildingDefinition in _buildings.values():
		for item_id: StringName in building.build_cost:
			if not _items.has(item_id):
				_set_error("Building '%s' references unknown cost item '%s'." % [String(building.id), String(item_id)])
				return false
		for item_id: StringName in building.storage_capacity_bonus:
			if not _items.has(item_id):
				_set_error("Building '%s' references unknown storage item '%s'." % [String(building.id), String(item_id)])
				return false
		if building.recipe_id != &"" and not _recipes.has(building.recipe_id):
			_set_error("Building '%s' references unknown recipe '%s'." % [String(building.id), String(building.recipe_id)])
			return false
		if building.recipe_id != &"":
			var recipe: RecipeDefinition = _recipes[building.recipe_id]
			if not building.capability_tags.has(recipe.required_capability_tag):
				_set_error("Building '%s' lacks capability '%s' required by recipe '%s'." % [String(building.id), String(recipe.required_capability_tag), String(recipe.id)])
				return false
	for recipe: RecipeDefinition in _recipes.values():
		for item_id: StringName in recipe.input_items:
			if not _items.has(item_id):
				_set_error("Recipe '%s' references unknown input item '%s'." % [String(recipe.id), String(item_id)])
				return false
		for item_id: StringName in recipe.output_items:
			if not _items.has(item_id):
				_set_error("Recipe '%s' references unknown output item '%s'." % [String(recipe.id), String(item_id)])
				return false
	return true


func _clear() -> void:
	_items.clear()
	_buildings.clear()
	_survival_configs.clear()
	_recipes.clear()
	_registered_ids.clear()
	_last_error = ""


func _fail_load(message: String) -> bool:
	_items.clear()
	_buildings.clear()
	_survival_configs.clear()
	_recipes.clear()
	_registered_ids.clear()
	_last_error = message
	return false


func _set_error(message: String) -> void:
	_last_error = message
