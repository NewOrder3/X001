class_name RaftGrid
extends RefCounted

signal grid_changed()

var _deck_cells: Dictionary[Vector2i, bool] = {}
var _occupied_cells: Dictionary[Vector2i, StringName] = {}
var _instance_cells: Dictionary[StringName, Array] = {}
var _footprints: Dictionary[StringName, Vector2i] = {}

func _init() -> void:
	for x: int in range(-1, 2):
		for y: int in range(-1, 2):
			_deck_cells[Vector2i(x, y)] = true

func set_building_footprint(building_id: StringName, footprint: Vector2i) -> void:
	_footprints[building_id] = footprint

func can_place(footprint: Vector2i, origin: Vector2i, rotation: int = 0) -> bool:
	var size: Vector2i = footprint
	if abs(rotation) % 2 == 1:
		size = Vector2i(footprint.y, footprint.x)
	for x: int in range(size.x):
		for y: int in range(size.y):
			var cell: Vector2i = origin + Vector2i(x, y)
			if not _deck_cells.has(cell) or _occupied_cells.has(cell):
				return false
	return true

func place(instance: BuildingInstance) -> bool:
	if _instance_cells.has(instance.instance_id) or not _footprints.has(instance.building_id):
		return false
	var footprint: Vector2i = _footprints[instance.building_id]
	if not can_place(footprint, instance.grid_position, instance.rotation):
		return false
	var cells: Array[Vector2i] = _get_cells(footprint, instance.grid_position, instance.rotation)
	for cell: Vector2i in cells:
		_occupied_cells[cell] = instance.instance_id
	_instance_cells[instance.instance_id] = cells
	grid_changed.emit()
	return true

func remove(instance_id: StringName) -> bool:
	if not _instance_cells.has(instance_id):
		return false
	var cells: Array = _instance_cells[instance_id]
	for cell: Vector2i in cells:
		_occupied_cells.erase(cell)
	_instance_cells.erase(instance_id)
	grid_changed.emit()
	return true

func is_walkable(cell: Vector2i) -> bool:
	return _deck_cells.has(cell) and not _occupied_cells.has(cell)


func get_deck_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell: Vector2i in _deck_cells:
		cells.append(cell)
	return cells


func to_save_data() -> Dictionary:
	var deck_cells: Array[Dictionary] = []
	var occupied_cells: Array[Dictionary] = []
	for cell: Vector2i in _deck_cells.keys():
		deck_cells.append({"x": cell.x, "y": cell.y})
	for cell: Vector2i in _occupied_cells.keys():
		occupied_cells.append({"x": cell.x, "y": cell.y, "instance_id": String(_occupied_cells[cell])})
	return {"deck_cells": deck_cells, "occupied_cells": occupied_cells}


func load_from_save_data(data: Dictionary) -> bool:
	var raw_deck_cells: Variant = data.get("deck_cells")
	var raw_occupied_cells: Variant = data.get("occupied_cells")
	if not raw_deck_cells is Array or not raw_occupied_cells is Array:
		return false
	_deck_cells.clear()
	_occupied_cells.clear()
	_instance_cells.clear()
	for raw_cell: Variant in raw_deck_cells:
		if not raw_cell is Dictionary:
			return false
		var cell: Vector2i = _dictionary_to_cell(raw_cell)
		_deck_cells[cell] = true
	for raw_cell: Variant in raw_occupied_cells:
		if not raw_cell is Dictionary or not raw_cell.has("instance_id"):
			return false
		var cell: Vector2i = _dictionary_to_cell(raw_cell)
		var instance_id: StringName = StringName(raw_cell["instance_id"])
		if not _deck_cells.has(cell) or _occupied_cells.has(cell):
			return false
		_occupied_cells[cell] = instance_id
		if not _instance_cells.has(instance_id):
			_instance_cells[instance_id] = []
		var cells: Array = _instance_cells[instance_id]
		cells.append(cell)
	grid_changed.emit()
	return true

func _get_cells(footprint: Vector2i, origin: Vector2i, rotation: int) -> Array[Vector2i]:
	var size: Vector2i = footprint if abs(rotation) % 2 == 0 else Vector2i(footprint.y, footprint.x)
	var cells: Array[Vector2i] = []
	for x: int in range(size.x):
		for y: int in range(size.y):
			cells.append(origin + Vector2i(x, y))
	return cells


func _dictionary_to_cell(data: Dictionary) -> Vector2i:
	return Vector2i(int(data.get("x", 0)), int(data.get("y", 0)))
