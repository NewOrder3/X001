extends "res://Tests/TestCase.gd"

func test_neighbors_have_distance_one() -> void:
	var origin: HexCoord = HexCoord.new(0, 0)
	for neighbor: HexCoord in HexGrid.get_neighbors(origin):
		assert_eq(HexGrid.distance_to(origin, neighbor), 1)

func test_world_round_trip_at_hex_centers() -> void:
	var source: HexCoord = HexCoord.new(-3, 5)
	var result: HexCoord = HexGrid.world_to_hex(HexGrid.hex_to_world(source))
	assert_true(source.equals(result))
