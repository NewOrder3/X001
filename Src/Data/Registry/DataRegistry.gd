class_name DataRegistry
extends RefCounted

## Central read-only access point for static Definitions.

const ITEM_DIRECTORY: String = "res://Data/Items"
const BUILDING_DIRECTORY: String = "res://Data/Buildings"
const SURVIVAL_DIRECTORY: String = "res://Data/Survival"
const RECIPE_DIRECTORY: String = "res://Data/Recipes"
const REGION_DIRECTORY: String = "res://Data/Regions"
const ENCOUNTER_DIRECTORY: String = "res://Data/Encounters"
const SURVIVOR_DIRECTORY: String = "res://Data/Survivors"
const SKILL_DIRECTORY: String = "res://Data/Skills"

var _item_directory: String
var _building_directory: String
var _survival_directory: String
var _recipe_directory: String
var _region_directory: String
var _encounter_directory: String
var _survivor_directory: String
var _skill_directory: String
var _items: Dictionary[StringName, ItemDefinition] = {}
var _buildings: Dictionary[StringName, BuildingDefinition] = {}
var _survival_configs: Dictionary[StringName, SurvivalConfigDefinition] = {}
var _recipes: Dictionary[StringName, RecipeDefinition] = {}
var _regions: Dictionary[StringName, RegionDefinition] = {}
var _encounters: Dictionary[StringName, EncounterDefinition] = {}
var _survivors: Dictionary[StringName, SurvivorDefinition] = {}
var _skills: Dictionary[StringName, SkillDefinition] = {}
var _registered_ids: Dictionary[StringName, bool] = {}
var _last_error: String = ""


func _init(
	new_item_directory: String = ITEM_DIRECTORY,
	new_building_directory: String = BUILDING_DIRECTORY,
	new_survival_directory: String = SURVIVAL_DIRECTORY,
	new_recipe_directory: String = "",
	new_region_directory: String = "",
	new_encounter_directory: String = "",
	new_survivor_directory: String = "",
	new_skill_directory: String = "",
) -> void:
	_item_directory = new_item_directory
	_building_directory = new_building_directory
	_survival_directory = new_survival_directory
	_recipe_directory = RECIPE_DIRECTORY if new_recipe_directory.is_empty() and new_item_directory == ITEM_DIRECTORY and new_building_directory == BUILDING_DIRECTORY else new_recipe_directory
	var use_default_content_directories: bool = new_item_directory == ITEM_DIRECTORY and new_building_directory == BUILDING_DIRECTORY and new_survival_directory == SURVIVAL_DIRECTORY
	_region_directory = REGION_DIRECTORY if new_region_directory.is_empty() and use_default_content_directories else new_region_directory
	_encounter_directory = ENCOUNTER_DIRECTORY if new_encounter_directory.is_empty() and use_default_content_directories else new_encounter_directory
	_survivor_directory = SURVIVOR_DIRECTORY if new_survivor_directory.is_empty() and use_default_content_directories else new_survivor_directory
	_skill_directory = SKILL_DIRECTORY if new_skill_directory.is_empty() and use_default_content_directories else new_skill_directory


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
	if not _region_directory.is_empty():
		var region_definitions: Array[RegionDefinition] = loader.load_regions(_region_directory)
		if not loader.get_last_error().is_empty():
			return _fail_load(loader.get_last_error())
		for definition: RegionDefinition in region_definitions:
			if not _register_region(definition):
				return _fail_load(_last_error)
	if not _encounter_directory.is_empty():
		var encounter_definitions: Array[EncounterDefinition] = loader.load_encounters(_encounter_directory)
		if not loader.get_last_error().is_empty():
			return _fail_load(loader.get_last_error())
		for definition: EncounterDefinition in encounter_definitions:
			if not _register_encounter(definition):
				return _fail_load(_last_error)
	if not _skill_directory.is_empty():
		var skill_definitions: Array[SkillDefinition] = loader.load_skills(_skill_directory)
		if not loader.get_last_error().is_empty():
			return _fail_load(loader.get_last_error())
		for definition: SkillDefinition in skill_definitions:
			if not _register_skill(definition):
				return _fail_load(_last_error)
	if not _survivor_directory.is_empty():
		var survivor_definitions: Array[SurvivorDefinition] = loader.load_survivors(_survivor_directory)
		if not loader.get_last_error().is_empty():
			return _fail_load(loader.get_last_error())
		for definition: SurvivorDefinition in survivor_definitions:
			if not _register_survivor(definition):
				return _fail_load(_last_error)
	if not _validate_building_item_references():
		return _fail_load(_last_error)
	if not _validate_world_references():
		return _fail_load(_last_error)
	if not _validate_survivor_references():
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


func get_region(id: StringName) -> RegionDefinition:
	if not _regions.has(id):
		push_error("DATA: Unknown region Definition ID '%s'." % String(id))
		return null
	return _regions[id]


func get_encounter(id: StringName) -> EncounterDefinition:
	if not _encounters.has(id):
		push_error("DATA: Unknown encounter Definition ID '%s'." % String(id))
		return null
	return _encounters[id]


func get_survivor(id: StringName) -> SurvivorDefinition:
	if not _survivors.has(id):
		push_error("DATA: Unknown survivor Definition ID '%s'." % String(id))
		return null
	return _survivors[id]


func get_skill(id: StringName) -> SkillDefinition:
	if not _skills.has(id):
		push_error("DATA: Unknown skill Definition ID '%s'." % String(id))
		return null
	return _skills[id]


func get_regions() -> Array[RegionDefinition]:
	var ids: Array[StringName] = []
	for region_id: StringName in _regions:
		ids.append(region_id)
	ids.sort()
	var definitions: Array[RegionDefinition] = []
	for region_id: StringName in ids:
		definitions.append(_regions[region_id])
	return definitions


func get_starting_region() -> RegionDefinition:
	for region: RegionDefinition in _regions.values():
		if region.is_starting_region:
			return region
	return null


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


func has_region(id: StringName) -> bool:
	return _regions.has(id)


func has_encounter(id: StringName) -> bool:
	return _encounters.has(id)


func has_survivor(id: StringName) -> bool:
	return _survivors.has(id)


func has_skill(id: StringName) -> bool:
	return _skills.has(id)


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


func get_region_count() -> int:
	return _regions.size()


func get_encounter_count() -> int:
	return _encounters.size()


func get_survivor_count() -> int:
	return _survivors.size()


func get_skill_count() -> int:
	return _skills.size()


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


func _register_region(definition: RegionDefinition) -> bool:
	if not _register_id(definition.id):
		return false
	_regions[definition.id] = definition
	return true


func _register_encounter(definition: EncounterDefinition) -> bool:
	if not _register_id(definition.id):
		return false
	_encounters[definition.id] = definition
	return true


func _register_survivor(definition: SurvivorDefinition) -> bool:
	if not _register_id(definition.id):
		return false
	_survivors[definition.id] = definition
	return true


func _register_skill(definition: SkillDefinition) -> bool:
	if not _register_id(definition.id):
		return false
	_skills[definition.id] = definition
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


func _validate_world_references() -> bool:
	if _regions.is_empty() and _encounters.is_empty():
		return true
	if _regions.is_empty() or _encounters.is_empty():
		_set_error("World Definitions require both regions and encounters.")
		return false
	var starting_region_count: int = 0
	var occupied_coordinates: Dictionary[Vector2i, bool] = {}
	for region: RegionDefinition in _regions.values():
		if region.is_starting_region:
			starting_region_count += 1
		if occupied_coordinates.has(region.coordinate):
			_set_error("Region '%s' duplicates a map coordinate." % String(region.id))
			return false
		occupied_coordinates[region.coordinate] = true
		if region.encounter_ids.is_empty():
			_set_error("Region '%s' requires at least one encounter." % String(region.id))
			return false
		for encounter_id: StringName in region.encounter_ids:
			if not _encounters.has(encounter_id):
				_set_error("Region '%s' references unknown encounter '%s'." % [String(region.id), String(encounter_id)])
				return false
	if starting_region_count != 1:
		_set_error("World Definitions require exactly one starting region.")
		return false
	for encounter: EncounterDefinition in _encounters.values():
		for item_id: StringName in encounter.reward_items:
			if not _items.has(item_id):
				_set_error("Encounter '%s' references unknown reward item '%s'." % [String(encounter.id), String(item_id)])
				return false
		if encounter.survivor_id != &"" and not _survivors.has(encounter.survivor_id):
			_set_error("Encounter '%s' references unknown survivor '%s'." % [String(encounter.id), String(encounter.survivor_id)])
			return false
	return true


func _validate_survivor_references() -> bool:
	if _survivors.is_empty() and _skills.is_empty():
		return true
	if _survivors.is_empty() or _skills.is_empty():
		_set_error("Survivor Definitions require both survivors and skills.")
		return false
	for survivor: SurvivorDefinition in _survivors.values():
		if not _skills.has(survivor.skill_id):
			_set_error("Survivor '%s' references unknown skill '%s'." % [String(survivor.id), String(survivor.skill_id)])
			return false
		for item_id: StringName in survivor.upgrade_cost:
			if not _items.has(item_id):
				_set_error("Survivor '%s' references unknown upgrade item '%s'." % [String(survivor.id), String(item_id)])
				return false
	return true


func _clear() -> void:
	_items.clear()
	_buildings.clear()
	_survival_configs.clear()
	_recipes.clear()
	_regions.clear()
	_encounters.clear()
	_survivors.clear()
	_skills.clear()
	_registered_ids.clear()
	_last_error = ""


func _fail_load(message: String) -> bool:
	_items.clear()
	_buildings.clear()
	_survival_configs.clear()
	_recipes.clear()
	_regions.clear()
	_encounters.clear()
	_survivors.clear()
	_skills.clear()
	_registered_ids.clear()
	_last_error = message
	return false


func _set_error(message: String) -> void:
	_last_error = message
