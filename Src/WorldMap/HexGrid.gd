class_name HexGrid
extends RefCounted

const HEX_SIZE: float = 96.0
const DIRECTIONS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)]

static func get_neighbors(coord: HexCoord) -> Array[HexCoord]:
	var neighbors: Array[HexCoord] = []
	for direction: Vector2i in DIRECTIONS:
		neighbors.append(HexCoord.new(coord.q + direction.x, coord.r + direction.y))
	return neighbors

static func distance_to(a: HexCoord, b: HexCoord) -> int:
	var dq: int = a.q - b.q
	var dr: int = a.r - b.r
	return int((abs(dq) + abs(dr) + abs(dq + dr)) / 2)

static func hex_to_world(coord: HexCoord) -> Vector2:
	return Vector2(sqrt(3.0) * HEX_SIZE * (float(coord.q) + float(coord.r) * 0.5), HEX_SIZE * 1.5 * float(coord.r))

static func world_to_hex(position: Vector2) -> HexCoord:
	var q_float: float = (sqrt(3.0) / 3.0 * position.x - position.y / 3.0) / HEX_SIZE
	var r_float: float = (position.y * 2.0 / 3.0) / HEX_SIZE
	return HexCoord.new(roundi(q_float), roundi(r_float))
