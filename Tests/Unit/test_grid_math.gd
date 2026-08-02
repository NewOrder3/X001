extends GutTest

func test_grid_world_round_trip() -> void:
	var cell: Vector2i = Vector2i(-3, 5)
	assert_eq(GridMath.world_to_grid(GridMath.grid_to_world(cell)), cell)
