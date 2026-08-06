extends "res://Tests/TestCase.gd"

const FIXTURE_ROOT: String = "res://Tests/Fixtures/DataRegistry"


func test_load_all_registers_valid_fixture_definitions() -> void:
	var registry: DataRegistry = DataRegistry.new(
		"%s/valid/Items" % FIXTURE_ROOT,
		"%s/valid/Buildings" % FIXTURE_ROOT,
		"%s/valid/Survival" % FIXTURE_ROOT,
	)
	assert_true(registry.load_all(), registry.get_last_error())
	assert_eq(registry.get_item_count(), 1)
	assert_eq(registry.get_building_count(), 1)
	assert_eq(registry.get_survival_config_count(), 1)
	assert_not_null(registry.get_item(&"item_fixture_wood"))
	assert_not_null(registry.get_building(&"building_fixture_collector"))
	var survival_config: SurvivalConfigDefinition = registry.get_survival_config(&"survival_fixture_default")
	assert_not_null(survival_config)
	assert_eq(survival_config.max_stamina, 10)
	assert_eq(survival_config.offline_supply_minimum, 1.0)


func test_load_all_rejects_invalid_json_without_partial_registration() -> void:
	var registry: DataRegistry = DataRegistry.new(
		"%s/invalid_json/Items" % FIXTURE_ROOT,
		"%s/invalid_json/Buildings" % FIXTURE_ROOT,
		"%s/valid/Survival" % FIXTURE_ROOT,
	)
	assert_false(registry.load_all())
	assert_true(registry.get_last_error().begins_with("Invalid JSON"))
	assert_eq(registry.get_item_count(), 0)
	assert_eq(registry.get_building_count(), 0)


func test_load_all_rejects_duplicate_ids_across_definition_types() -> void:
	var registry: DataRegistry = DataRegistry.new(
		"%s/duplicate_ids/Items" % FIXTURE_ROOT,
		"%s/duplicate_ids/Buildings" % FIXTURE_ROOT,
		"%s/valid/Survival" % FIXTURE_ROOT,
	)
	assert_false(registry.load_all())
	assert_true(registry.get_last_error().begins_with("Duplicate Definition ID"))
	assert_eq(registry.get_item_count(), 0)
	assert_eq(registry.get_building_count(), 0)


func test_unknown_definition_id_is_not_registered() -> void:
	var registry: DataRegistry = DataRegistry.new(
		"%s/valid/Items" % FIXTURE_ROOT,
		"%s/valid/Buildings" % FIXTURE_ROOT,
		"%s/valid/Survival" % FIXTURE_ROOT,
	)
	assert_true(registry.load_all(), registry.get_last_error())
	assert_false(registry.has_definition(&"item_missing"))


func test_load_all_rejects_building_cost_for_unknown_item() -> void:
	var registry: DataRegistry = DataRegistry.new(
		"%s/valid/Items" % FIXTURE_ROOT,
		"%s/unknown_cost/Buildings" % FIXTURE_ROOT,
		"%s/valid/Survival" % FIXTURE_ROOT,
	)
	assert_false(registry.load_all())
	assert_true(registry.get_last_error().begins_with("Building 'building_fixture_collector' references unknown cost item"))


func test_load_all_rejects_survival_threshold_above_its_maximum() -> void:
	var registry: DataRegistry = DataRegistry.new(
		"%s/valid/Items" % FIXTURE_ROOT,
		"%s/valid/Buildings" % FIXTURE_ROOT,
		"%s/invalid_survival/Survival" % FIXTURE_ROOT,
	)
	assert_false(registry.load_all())
	assert_true(registry.get_last_error().begins_with("Definition 'res://Tests/Fixtures/DataRegistry/invalid_survival/Survival/invalid_threshold.json' has a supply value above max_supply."))
	assert_eq(registry.get_survival_config_count(), 0)


func test_default_registry_loads_s3_recipe_definitions() -> void:
	var registry: DataRegistry = DataRegistry.new()
	assert_true(registry.load_all(), registry.get_last_error())
	assert_eq(registry.get_recipe_count(), 2)
	assert_not_null(registry.get_recipe(&"recipe_grill_fish"))
	assert_eq(registry.get_survivor_count(), 4)
	assert_eq(registry.get_skill_count(), 4)
	assert_eq(registry.get_boss_count(), 1)
	assert_eq(registry.get_reward_count(), 1)
	assert_not_null(registry.get_survivor(&"survivor_marin"))
	assert_not_null(registry.get_skill(&"skill_anchor_strike"))
	assert_not_null(registry.get_boss(&"boss_tutorial_sea_beast"))
	assert_not_null(registry.get_reward(&"reward_tutorial_cache"))
	assert_eq(registry.get_skill(&"skill_anchor_strike").power, 10)


func test_default_definition_text_uses_stable_key_and_chinese_translation() -> void:
	GameText.initialize()
	var registry: DataRegistry = DataRegistry.new()
	assert_true(registry.load_all(), registry.get_last_error())
	var wood: ItemDefinition = registry.get_item(&"item_wood")
	assert_not_null(wood)
	if wood == null:
		return
	assert_eq(wood.display_name_key, &"data.item.wood.name")
	assert_eq(wood.get_display_name(), "木材")
