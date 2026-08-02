class_name JsonDefinitionLoader
extends RefCounted

## Loads static Definition JSON files. Registry owns registration and duplicate checks.

var _last_error: String = ""


func load_items(directory_path: String) -> Array[ItemDefinition]:
	var definitions: Array[ItemDefinition] = []
	var entries: Array[Dictionary] = _load_json_entries(directory_path)
	if not _last_error.is_empty():
		return definitions

	for entry: Dictionary in entries:
		var data: Dictionary = entry["data"]
		var source_path: String = entry["source_path"]
		var definition: ItemDefinition = _create_item_definition(data, source_path)
		if definition == null:
			return []
		definitions.append(definition)

	return definitions


func load_buildings(directory_path: String) -> Array[BuildingDefinition]:
	var definitions: Array[BuildingDefinition] = []
	var entries: Array[Dictionary] = _load_json_entries(directory_path)
	if not _last_error.is_empty():
		return definitions

	for entry: Dictionary in entries:
		var data: Dictionary = entry["data"]
		var source_path: String = entry["source_path"]
		var definition: BuildingDefinition = _create_building_definition(data, source_path)
		if definition == null:
			return []
		definitions.append(definition)

	return definitions


func get_last_error() -> String:
	return _last_error


func _load_json_entries(directory_path: String) -> Array[Dictionary]:
	_last_error = ""
	var entries: Array[Dictionary] = []
	var directory: DirAccess = DirAccess.open(directory_path)
	if directory == null:
		_set_error("Cannot open Definition directory '%s'." % directory_path)
		return entries

	var file_names: PackedStringArray = directory.get_files()
	file_names.sort()
	for file_name: String in file_names:
		if file_name.get_extension().to_lower() != "json":
			continue

		var file_path: String = directory_path.path_join(file_name)
		var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
		if file == null:
			_set_error("Cannot read Definition file '%s'." % file_path)
			return []

		var json_text: String = file.get_as_text()
		file.close()
		var json: JSON = JSON.new()
		var parse_result: Error = json.parse(json_text)
		if parse_result != OK:
			_set_error("Invalid JSON in '%s': %s" % [file_path, json.get_error_message()])
			return []
		if typeof(json.data) != TYPE_DICTIONARY:
			_set_error("Definition file '%s' must contain a JSON object." % file_path)
			return []

		entries.append({"data": json.data, "source_path": file_path})

	return entries


func _create_item_definition(data: Dictionary, source_path: String) -> ItemDefinition:
	var id: StringName = _read_id(data, source_path)
	if not _last_error.is_empty():
		return null

	var display_name: String = _read_required_string(data, "display_name", source_path)
	if not _last_error.is_empty():
		return null

	var description: String = _read_required_string(data, "description", source_path)
	if not _last_error.is_empty():
		return null

	return ItemDefinition.new(id, display_name, description)


func _create_building_definition(data: Dictionary, source_path: String) -> BuildingDefinition:
	var id: StringName = _read_id(data, source_path)
	if not _last_error.is_empty():
		return null

	var display_name: String = _read_required_string(data, "display_name", source_path)
	if not _last_error.is_empty():
		return null

	var description: String = _read_required_string(data, "description", source_path)
	if not _last_error.is_empty():
		return null

	var footprint_width: int = _read_positive_int(data, "footprint_width", source_path)
	if not _last_error.is_empty():
		return null

	var footprint_height: int = _read_positive_int(data, "footprint_height", source_path)
	if not _last_error.is_empty():
		return null

	return BuildingDefinition.new(
		id,
		display_name,
		description,
		Vector2i(footprint_width, footprint_height),
	)


func _read_id(data: Dictionary, source_path: String) -> StringName:
	var raw_id: Variant = data.get("id")
	if typeof(raw_id) != TYPE_STRING:
		_set_error("Definition '%s' requires a string field named 'id'." % source_path)
		return &""

	var id: StringName = StringName(raw_id)
	var validation_error: String = IdValidator.get_validation_error(id)
	if not validation_error.is_empty():
		_set_error("Invalid ID '%s' in '%s': %s" % [raw_id, source_path, validation_error])
		return &""

	return id


func _read_required_string(data: Dictionary, field_name: String, source_path: String) -> String:
	var raw_value: Variant = data.get(field_name)
	if typeof(raw_value) != TYPE_STRING or String(raw_value).is_empty():
		_set_error("Definition '%s' requires a non-empty string field named '%s'." % [source_path, field_name])
		return ""

	return String(raw_value)


func _read_positive_int(data: Dictionary, field_name: String, source_path: String) -> int:
	var raw_value: Variant = data.get(field_name)
	if typeof(raw_value) != TYPE_INT and typeof(raw_value) != TYPE_FLOAT:
		_set_error("Definition '%s' requires a positive integer field named '%s'." % [source_path, field_name])
		return 0

	var value: float = float(raw_value)
	if value <= 0.0 or value != floor(value):
		_set_error("Definition '%s' requires a positive integer field named '%s'." % [source_path, field_name])
		return 0

	return int(value)


func _set_error(message: String) -> void:
	_last_error = message
