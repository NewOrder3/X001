class_name DataRegistry
extends RefCounted

## Central read-only access point for static Definitions.

const ITEM_DIRECTORY: String = "res://Data/Items"
const BUILDING_DIRECTORY: String = "res://Data/Buildings"
const PROGRESSION_DIRECTORY: String = "res://Data/Progression"
const SURVIVAL_DIRECTORY: String = "res://Data/Survival"
const RECIPE_DIRECTORY: String = "res://Data/Recipes"
const MERCHANT_DIRECTORY: String = "res://Data/Merchants"
const REGION_DIRECTORY: String = "res://Data/Regions"
const ENCOUNTER_DIRECTORY: String = "res://Data/Encounters"
const SURVIVOR_DIRECTORY: String = "res://Data/Survivors"
const SKILL_DIRECTORY: String = "res://Data/Skills"
const BOSS_DIRECTORY: String = "res://Data/Bosses"
const REWARD_DIRECTORY: String = "res://Data/Rewards"

var _item_directory: String
var _building_directory: String
var _progression_directory: String
var _survival_directory: String
var _recipe_directory: String
var _merchant_directory: String
var _region_directory: String
var _encounter_directory: String
var _survivor_directory: String
var _skill_directory: String
var _boss_directory: String
var _reward_directory: String
var _items: Dictionary[StringName, ItemDefinition] = {}
var _buildings: Dictionary[StringName, BuildingDefinition] = {}
var _progressions: Dictionary[StringName, ProgressionDefinition] = {}
var _survival_configs: Dictionary[StringName, SurvivalConfigDefinition] = {}
var _recipes: Dictionary[StringName, RecipeDefinition] = {}
var _merchants: Dictionary[StringName, MerchantDefinition] = {}
var _merchant_offers: Dictionary[StringName, MerchantOfferDefinition] = {}
var _regions: Dictionary[StringName, RegionDefinition] = {}
var _encounters: Dictionary[StringName, EncounterDefinition] = {}
var _survivors: Dictionary[StringName, SurvivorDefinition] = {}
var _skills: Dictionary[StringName, SkillDefinition] = {}
var _bosses: Dictionary[StringName, BossDefinition] = {}
var _rewards: Dictionary[StringName, RewardDefinition] = {}
var _registered_ids: Dictionary[StringName, bool] = {}
var _last_error: String = ""


func _init(
	new_item_directory: String = ITEM_DIRECTORY,
	new_building_directory: String = BUILDING_DIRECTORY,
	new_survival_directory: String = SURVIVAL_DIRECTORY,
	new_recipe_directory: String = "",
	new_merchant_directory: String = "",
	new_region_directory: String = "",
	new_encounter_directory: String = "",
	new_survivor_directory: String = "",
	new_skill_directory: String = "",
	new_boss_directory: String = "",
	new_reward_directory: String = "",
	new_progression_directory: String = "",
) -> void:
	_item_directory = new_item_directory
	_building_directory = new_building_directory
	_survival_directory = new_survival_directory
	_recipe_directory = RECIPE_DIRECTORY if new_recipe_directory.is_empty() and new_item_directory == ITEM_DIRECTORY and new_building_directory == BUILDING_DIRECTORY else new_recipe_directory
	_merchant_directory = new_merchant_directory
	var use_default_content_directories: bool = new_item_directory == ITEM_DIRECTORY and new_building_directory == BUILDING_DIRECTORY and new_survival_directory == SURVIVAL_DIRECTORY
	if _merchant_directory.is_empty() and use_default_content_directories:
		_merchant_directory = MERCHANT_DIRECTORY
	_region_directory = REGION_DIRECTORY if new_region_directory.is_empty() and use_default_content_directories else new_region_directory
	_encounter_directory = ENCOUNTER_DIRECTORY if new_encounter_directory.is_empty() and use_default_content_directories else new_encounter_directory
	_survivor_directory = SURVIVOR_DIRECTORY if new_survivor_directory.is_empty() and use_default_content_directories else new_survivor_directory
	_skill_directory = SKILL_DIRECTORY if new_skill_directory.is_empty() and use_default_content_directories else new_skill_directory
	_boss_directory = BOSS_DIRECTORY if new_boss_directory.is_empty() and use_default_content_directories else new_boss_directory
	_reward_directory = REWARD_DIRECTORY if new_reward_directory.is_empty() and use_default_content_directories else new_reward_directory
	_progression_directory = PROGRESSION_DIRECTORY if new_progression_directory.is_empty() and use_default_content_directories else new_progression_directory


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

	if not _progression_directory.is_empty():
		var progression_definitions: Array[ProgressionDefinition] = loader.load_progressions(_progression_directory)
		if not loader.get_last_error().is_empty():
			return _fail_load(loader.get_last_error())
		for definition: ProgressionDefinition in progression_definitions:
			if not _register_progression(definition):
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
	if not _merchant_directory.is_empty():
		var merchant_definitions: Array[MerchantDefinition] = loader.load_merchants(_merchant_directory)
		if not loader.get_last_error().is_empty():
			return _fail_load(loader.get_last_error())
		for definition: MerchantDefinition in merchant_definitions:
			if not _register_merchant(definition):
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
	if not _reward_directory.is_empty():
		var reward_definitions: Array[RewardDefinition] = loader.load_rewards(_reward_directory)
		if not loader.get_last_error().is_empty():
			return _fail_load(loader.get_last_error())
		for definition: RewardDefinition in reward_definitions:
			if not _register_reward(definition):
				return _fail_load(_last_error)
	if not _boss_directory.is_empty():
		var boss_definitions: Array[BossDefinition] = loader.load_bosses(_boss_directory)
		if not loader.get_last_error().is_empty():
			return _fail_load(loader.get_last_error())
		for definition: BossDefinition in boss_definitions:
			if not _register_boss(definition):
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
	if not _validate_progression_references():
		return _fail_load(_last_error)
	if not _validate_merchant_references():
		return _fail_load(_last_error)
	if not _validate_world_references():
		return _fail_load(_last_error)
	if not _validate_survivor_references():
		return _fail_load(_last_error)
	if not _validate_battle_references():
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


func get_progression(id: StringName) -> ProgressionDefinition:
	if not _progressions.has(id):
		push_error("DATA: Unknown progression Definition ID '%s'." % String(id))
		return null
	return _progressions[id]


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


func get_merchant(id: StringName) -> MerchantDefinition:
	if not _merchants.has(id):
		push_error("DATA: Unknown merchant Definition ID '%s'." % String(id))
		return null
	return _merchants[id]


func get_merchant_offer(id: StringName) -> MerchantOfferDefinition:
	if not _merchant_offers.has(id):
		push_error("DATA: Unknown merchant offer ID '%s'." % String(id))
		return null
	return _merchant_offers[id]


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


func get_boss(id: StringName) -> BossDefinition:
	if not _bosses.has(id):
		push_error("DATA: Unknown boss Definition ID '%s'." % String(id))
		return null
	return _bosses[id]


func get_reward(id: StringName) -> RewardDefinition:
	if not _rewards.has(id):
		push_error("DATA: Unknown reward Definition ID '%s'." % String(id))
		return null
	return _rewards[id]


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


func has_progression(id: StringName) -> bool:
	return _progressions.has(id)


func has_survival_config(id: StringName) -> bool:
	return _survival_configs.has(id)


func has_recipe(id: StringName) -> bool:
	return _recipes.has(id)


func has_merchant(id: StringName) -> bool:
	return _merchants.has(id)


func has_merchant_offer(id: StringName) -> bool:
	return _merchant_offers.has(id)


func has_region(id: StringName) -> bool:
	return _regions.has(id)


func has_encounter(id: StringName) -> bool:
	return _encounters.has(id)


func has_survivor(id: StringName) -> bool:
	return _survivors.has(id)


func has_skill(id: StringName) -> bool:
	return _skills.has(id)


func has_boss(id: StringName) -> bool:
	return _bosses.has(id)


func has_reward(id: StringName) -> bool:
	return _rewards.has(id)


func get_last_error() -> String:
	return _last_error


func get_item_count() -> int:
	return _items.size()


func get_building_count() -> int:
	return _buildings.size()


func get_progression_count() -> int:
	return _progressions.size()


func get_survival_config_count() -> int:
	return _survival_configs.size()


func get_recipe_count() -> int:
	return _recipes.size()


func get_merchant_count() -> int:
	return _merchants.size()


func get_merchant_offer_count() -> int:
	return _merchant_offers.size()


func get_region_count() -> int:
	return _regions.size()


func get_encounter_count() -> int:
	return _encounters.size()


func get_survivor_count() -> int:
	return _survivors.size()


func get_skill_count() -> int:
	return _skills.size()


func get_boss_count() -> int:
	return _bosses.size()


func get_reward_count() -> int:
	return _rewards.size()


func get_merchants() -> Array[MerchantDefinition]:
	var ids: Array[StringName] = []
	for merchant_id: StringName in _merchants:
		ids.append(merchant_id)
	ids.sort()
	var definitions: Array[MerchantDefinition] = []
	for merchant_id: StringName in ids:
		definitions.append(_merchants[merchant_id])
	return definitions


func get_raft_level_progression(raft_level_value: int) -> ProgressionDefinition:
	for definition: ProgressionDefinition in _progressions.values():
		if definition.is_raft_level() and definition.raft_level == raft_level_value:
			return definition
	return null


func get_unlock_progression(unlock_id: StringName) -> ProgressionDefinition:
	for definition: ProgressionDefinition in _progressions.values():
		if definition.is_unlock() and definition.unlock_id == unlock_id:
			return definition
	return null


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


func _register_progression(definition: ProgressionDefinition) -> bool:
	if not _register_id(definition.id):
		return false
	_progressions[definition.id] = definition
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


func _register_merchant(definition: MerchantDefinition) -> bool:
	if not _register_id(definition.id):
		return false
	_merchants[definition.id] = definition
	for offer: MerchantOfferDefinition in definition.offers:
		if not _register_id(offer.id):
			return false
		_merchant_offers[offer.id] = offer
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


func _register_boss(definition: BossDefinition) -> bool:
	if not _register_id(definition.id):
		return false
	_bosses[definition.id] = definition
	return true


func _register_reward(definition: RewardDefinition) -> bool:
	if not _register_id(definition.id):
		return false
	_rewards[definition.id] = definition
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


func _validate_merchant_references() -> bool:
	if _merchants.is_empty():
		return true
	for merchant: MerchantDefinition in _merchants.values():
		for offer: MerchantOfferDefinition in merchant.offers:
			if not _items.has(offer.item_id):
				_set_error("Merchant '%s' offer '%s' references unknown item '%s'." % [String(merchant.id), String(offer.id), String(offer.item_id)])
				return false
			for item_id: StringName in offer.cost:
				if not _items.has(item_id):
					_set_error("Merchant '%s' offer '%s' references unknown cost item '%s'." % [String(merchant.id), String(offer.id), String(item_id)])
					return false
	return true


func _validate_progression_references() -> bool:
	if _progressions.is_empty():
		return true
	var raft_levels: Dictionary[int, bool] = {}
	var unlock_ids: Dictionary[StringName, bool] = {}
	var max_raft_level: int = 0
	for definition: ProgressionDefinition in _progressions.values():
		if definition.is_raft_level():
			if raft_levels.has(definition.raft_level):
				_set_error("Progression '%s' duplicates raft level %d." % [String(definition.id), definition.raft_level])
				return false
			raft_levels[definition.raft_level] = true
			max_raft_level = maxi(max_raft_level, definition.raft_level)
			for item_id: StringName in definition.upgrade_cost:
				if not _items.has(item_id):
					_set_error("Progression '%s' references unknown cost item '%s'." % [String(definition.id), String(item_id)])
					return false
		else:
			if definition.unlock_id == &"":
				_set_error("Progression '%s' requires a non-empty unlock_id." % String(definition.id))
				return false
			if unlock_ids.has(definition.unlock_id):
				_set_error("Progression '%s' duplicates unlock '%s'." % [String(definition.id), String(definition.unlock_id)])
				return false
			unlock_ids[definition.unlock_id] = true
			if definition.required_building_id != &"" and not _buildings.has(definition.required_building_id):
				_set_error("Progression '%s' references unknown building '%s'." % [String(definition.id), String(definition.required_building_id)])
				return false
	if raft_levels.is_empty():
		_set_error("Progression Definitions require at least one raft level.")
		return false
	if not raft_levels.has(1):
		_set_error("Progression Definitions require raft level 1.")
		return false
	for level: int in range(1, max_raft_level + 1):
		if not raft_levels.has(level):
			_set_error("Progression raft levels must be contiguous; missing level %d." % level)
			return false
		var level_definition: ProgressionDefinition = get_raft_level_progression(level)
		if level_definition.raft_width <= 0 or level_definition.raft_height <= 0:
			_set_error("Progression '%s' requires positive raft dimensions." % String(level_definition.id))
			return false
		if level < max_raft_level and level_definition.upgrade_cost.is_empty():
			_set_error("Progression raft level %d requires an upgrade_cost." % level)
			return false
		if level == max_raft_level and not level_definition.upgrade_cost.is_empty():
			_set_error("Progression final raft level %d must not define upgrade_cost." % level)
			return false
	for definition: ProgressionDefinition in _progressions.values():
		if definition.is_unlock() and definition.required_raft_level > max_raft_level:
			_set_error("Progression '%s' requires raft level %d above the maximum %d." % [String(definition.id), definition.required_raft_level, max_raft_level])
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


func _validate_battle_references() -> bool:
	if _bosses.is_empty() and _rewards.is_empty():
		return true
	if _bosses.is_empty() or _rewards.is_empty():
		_set_error("Battle Definitions require both bosses and rewards.")
		return false
	for boss: BossDefinition in _bosses.values():
		if not _rewards.has(boss.reward_id):
			_set_error("Boss '%s' references unknown reward '%s'." % [String(boss.id), String(boss.reward_id)])
			return false
		if boss.unlock_id != &"" and get_unlock_progression(boss.unlock_id) == null:
			_set_error("Boss '%s' references unknown unlock '%s'." % [String(boss.id), String(boss.unlock_id)])
			return false
	for reward: RewardDefinition in _rewards.values():
		for item_id: StringName in reward.item_rewards:
			if not _items.has(item_id):
				_set_error("Reward '%s' references unknown item '%s'." % [String(reward.id), String(item_id)])
				return false
	return true


func _clear() -> void:
	_items.clear()
	_buildings.clear()
	_progressions.clear()
	_survival_configs.clear()
	_recipes.clear()
	_merchants.clear()
	_merchant_offers.clear()
	_regions.clear()
	_encounters.clear()
	_survivors.clear()
	_skills.clear()
	_bosses.clear()
	_rewards.clear()
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
	_bosses.clear()
	_rewards.clear()
	_registered_ids.clear()
	_last_error = message
	return false


func _set_error(message: String) -> void:
	_last_error = message
