extends "res://Tests/TestCase.gd"

const FIXTURE_ROOT: String = "res://Tests/Fixtures/DataRegistry"


func test_load_all_registers_valid_fixture_definitions() -> void:
	var registry: DataRegistry = DataRegistry.new(
		"%s/valid/Items" % FIXTURE_ROOT,
		"%s/valid/Buildings" % FIXTURE_ROOT,
	)
	assert_true(registry.load_all(), registry.get_last_error())
	assert_eq(registry.get_item_count(), 1)
	assert_eq(registry.get_building_count(), 1)
	assert_not_null(registry.get_item(&"item_fixture_wood"))
	assert_not_null(registry.get_building(&"building_fixture_collector"))


func test_load_all_rejects_invalid_json_without_partial_registration() -> void:
	var registry: DataRegistry = DataRegistry.new(
		"%s/invalid_json/Items" % FIXTURE_ROOT,
		"%s/invalid_json/Buildings" % FIXTURE_ROOT,
	)
	assert_false(registry.load_all())
	assert_true(registry.get_last_error().begins_with("Invalid JSON"))
	assert_eq(registry.get_item_count(), 0)
	assert_eq(registry.get_building_count(), 0)


func test_load_all_rejects_duplicate_ids_across_definition_types() -> void:
	var registry: DataRegistry = DataRegistry.new(
		"%s/duplicate_ids/Items" % FIXTURE_ROOT,
		"%s/duplicate_ids/Buildings" % FIXTURE_ROOT,
	)
	assert_false(registry.load_all())
	assert_true(registry.get_last_error().begins_with("Duplicate Definition ID"))
	assert_eq(registry.get_item_count(), 0)
	assert_eq(registry.get_building_count(), 0)


func test_unknown_definition_id_is_not_registered() -> void:
	var registry: DataRegistry = DataRegistry.new(
		"%s/valid/Items" % FIXTURE_ROOT,
		"%s/valid/Buildings" % FIXTURE_ROOT,
	)
	assert_true(registry.load_all(), registry.get_last_error())
	assert_false(registry.has_definition(&"item_missing"))


func test_load_all_rejects_building_cost_for_unknown_item() -> void:
	var registry: DataRegistry = DataRegistry.new(
		"%s/valid/Items" % FIXTURE_ROOT,
		"%s/unknown_cost/Buildings" % FIXTURE_ROOT,
	)
	assert_false(registry.load_all())
	assert_true(registry.get_last_error().begins_with("Building 'building_fixture_collector' references unknown cost item"))
