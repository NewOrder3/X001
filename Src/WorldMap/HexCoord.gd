class_name HexCoord
extends RefCounted

var q: int
var r: int

func _init(new_q: int = 0, new_r: int = 0) -> void:
	q = new_q
	r = new_r

func equals(other: HexCoord) -> bool:
	return other != null and q == other.q and r == other.r
