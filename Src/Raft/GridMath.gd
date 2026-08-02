class_name GridMath
extends RefCounted

const CELL_WIDTH: float = 128.0
const CELL_HEIGHT: float = 64.0
const HALF_WIDTH: float = CELL_WIDTH * 0.5
const HALF_HEIGHT: float = CELL_HEIGHT * 0.5

static func grid_to_world(cell: Vector2i) -> Vector2:
	return Vector2((cell.x - cell.y) * HALF_WIDTH, (cell.x + cell.y) * HALF_HEIGHT)

static func world_to_grid(position: Vector2) -> Vector2i:
	var x_axis: float = position.x / HALF_WIDTH
	var y_axis: float = position.y / HALF_HEIGHT
	return Vector2i(roundi((x_axis + y_axis) * 0.5), roundi((y_axis - x_axis) * 0.5))

static func get_cell_polygon(cell: Vector2i) -> PackedVector2Array:
	var center: Vector2 = grid_to_world(cell)
	return PackedVector2Array([
		center + Vector2(0.0, -HALF_HEIGHT),
		center + Vector2(HALF_WIDTH, 0.0),
		center + Vector2(0.0, HALF_HEIGHT),
		center + Vector2(-HALF_WIDTH, 0.0),
	])
