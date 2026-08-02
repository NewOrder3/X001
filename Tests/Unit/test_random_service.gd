extends "res://Tests/TestCase.gd"

func test_same_seed_produces_same_value() -> void:
	var first: RandomService = RandomService.new()
	var second: RandomService = RandomService.new()
	first.set_world_seed(42)
	second.set_world_seed(42)
	assert_eq(first.range_i(1, 99), second.range_i(1, 99))
