extends "res://Tests/TestCase.gd"

func test_place_remove_and_overlap_rules() -> void:
	var raft: RaftGrid = RaftGrid.new()
	raft.set_building_footprint(&"building_large", Vector2i(2, 2))
	var instance: BuildingInstance = BuildingInstance.new(&"instance_large", &"building_large", Vector2i(-1, -1))
	assert_true(raft.place(instance))
	assert_false(raft.can_place(Vector2i.ONE, Vector2i(-1, -1)))
	assert_false(raft.is_walkable(Vector2i(0, 0)))
	assert_true(raft.remove(&"instance_large"))
	assert_true(raft.is_walkable(Vector2i(0, 0)))


func test_rotation_swaps_footprint_dimensions() -> void:
	var raft: RaftGrid = RaftGrid.new()
	raft.set_building_footprint(&"building_rotated", Vector2i(2, 1))
	var instance: BuildingInstance = BuildingInstance.new(
		&"instance_rotated",
		&"building_rotated",
		Vector2i(-1, -1),
		1,
	)
	assert_true(raft.place(instance))
	assert_false(raft.is_walkable(Vector2i(-1, -1)))
	assert_false(raft.is_walkable(Vector2i(-1, 0)))
	assert_true(raft.is_walkable(Vector2i(0, -1)))
