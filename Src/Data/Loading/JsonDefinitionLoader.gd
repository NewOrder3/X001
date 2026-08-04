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


func load_survival_configs(directory_path: String) -> Array[SurvivalConfigDefinition]:
	var definitions: Array[SurvivalConfigDefinition] = []
	var entries: Array[Dictionary] = _load_json_entries(directory_path)
	if not _last_error.is_empty():
		return definitions

	for entry: Dictionary in entries:
		var data: Dictionary = entry["data"]
		var source_path: String = entry["source_path"]
		var definition: SurvivalConfigDefinition = _create_survival_config_definition(data, source_path)
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

	var build_cost: Dictionary[StringName, int] = _read_item_amounts(data, "build_cost", source_path)
	if not _last_error.is_empty():
		return null

	return BuildingDefinition.new(
		id,
		display_name,
		description,
		Vector2i(footprint_width, footprint_height),
		build_cost,
	)


func _create_survival_config_definition(
	data: Dictionary,
	source_path: String,
) -> SurvivalConfigDefinition:
	var id: StringName = _read_id(data, source_path)
	if not _last_error.is_empty():
		return null
	if not String(id).begins_with("survival_"):
		_set_error("Definition '%s' requires an ID beginning with 'survival_'." % source_path)
		return null

	var max_supply: float = _read_positive_float(data, "max_supply", source_path)
	var max_durability: float = _read_positive_float(data, "max_durability", source_path)
	var online_supply_rate: float = _read_nonnegative_float(data, "online_supply_rate_per_minute", source_path)
	var offline_supply_rate: float = _read_nonnegative_float(data, "offline_supply_rate_per_minute", source_path)
	var offline_supply_minimum: float = _read_nonnegative_float(data, "offline_supply_minimum", source_path)
	var passive_recovery_rate: float = _read_nonnegative_float(data, "passive_supply_recovery_per_minute", source_path)
	var accelerated_multiplier: float = _read_positive_float(data, "passive_recovery_accelerated_multiplier", source_path)
	var accelerated_threshold: float = _read_nonnegative_float(data, "passive_recovery_accelerated_threshold", source_path)
	var online_durability_loss: float = _read_nonnegative_float(data, "online_durability_loss_per_hour", source_path)
	var supply_modifier_cap: float = _read_nonnegative_float(data, "supply_modifier_cap", source_path)
	var durability_modifier_cap: float = _read_nonnegative_float(data, "durability_modifier_cap", source_path)
	var supply_warning_threshold: float = _read_nonnegative_float(data, "supply_warning_threshold", source_path)
	var supply_safe_line: float = _read_nonnegative_float(data, "supply_safe_line", source_path)
	var durability_warning_threshold: float = _read_nonnegative_float(data, "durability_warning_threshold", source_path)
	var durability_safe_line: float = _read_nonnegative_float(data, "durability_safe_line", source_path)
	var simulation_interval: float = _read_positive_float(data, "simulation_interval_seconds", source_path)
	var max_stamina: int = _read_positive_int(data, "max_stamina", source_path)
	var explore_stamina_cost: int = _read_positive_int(data, "explore_stamina_cost", source_path)
	var battle_stamina_cost: int = _read_positive_int(data, "battle_stamina_cost", source_path)
	var stamina_recovery_interval: int = _read_positive_int(data, "stamina_recovery_interval_minutes", source_path)
	var stamina_offline_recovery: bool = _read_required_bool(data, "stamina_offline_recovery", source_path)
	var stamina_warning_threshold: int = _read_nonnegative_int(data, "stamina_warning_threshold", source_path)
	var stamina_safe_line: int = _read_nonnegative_int(data, "stamina_safe_line", source_path)
	var action_supply_cost: float = _read_nonnegative_float(data, "action_supply_cost", source_path)
	if not _last_error.is_empty():
		return null

	if offline_supply_minimum <= 0.0:
		_set_error("Definition '%s' requires offline_supply_minimum to be greater than zero." % source_path)
		return null
	if offline_supply_minimum > max_supply or accelerated_threshold > max_supply or supply_warning_threshold > max_supply or supply_safe_line > max_supply:
		_set_error("Definition '%s' has a supply value above max_supply." % source_path)
		return null
	if durability_warning_threshold > max_durability or durability_safe_line > max_durability:
		_set_error("Definition '%s' has a durability threshold above max_durability." % source_path)
		return null
	if stamina_warning_threshold > max_stamina or stamina_safe_line > max_stamina:
		_set_error("Definition '%s' has a stamina threshold above max_stamina." % source_path)
		return null
	if supply_safe_line < supply_warning_threshold or durability_safe_line < durability_warning_threshold or stamina_safe_line < stamina_warning_threshold:
		_set_error("Definition '%s' requires each safe line to be at or above its warning threshold." % source_path)
		return null
	if explore_stamina_cost > max_stamina or battle_stamina_cost > max_stamina:
		_set_error("Definition '%s' has a stamina action cost above max_stamina." % source_path)
		return null

	return SurvivalConfigDefinition.new(
		id, max_supply, max_durability, online_supply_rate, offline_supply_rate,
		offline_supply_minimum, passive_recovery_rate, accelerated_multiplier,
		accelerated_threshold, online_durability_loss, supply_modifier_cap, durability_modifier_cap,
		supply_warning_threshold, supply_safe_line, durability_warning_threshold,
		durability_safe_line, simulation_interval, max_stamina, explore_stamina_cost,
		battle_stamina_cost, stamina_recovery_interval, stamina_offline_recovery,
		stamina_warning_threshold, stamina_safe_line, action_supply_cost,
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


func _read_nonnegative_int(data: Dictionary, field_name: String, source_path: String) -> int:
	var value: float = _read_number(data, field_name, source_path)
	if not _last_error.is_empty():
		return 0
	if value < 0.0 or value != floor(value):
		_set_error("Definition '%s' requires a non-negative integer field named '%s'." % [source_path, field_name])
		return 0
	return int(value)


func _read_positive_float(data: Dictionary, field_name: String, source_path: String) -> float:
	var value: float = _read_number(data, field_name, source_path)
	if not _last_error.is_empty():
		return 0.0
	if value <= 0.0:
		_set_error("Definition '%s' requires a positive number field named '%s'." % [source_path, field_name])
		return 0.0
	return value


func _read_nonnegative_float(data: Dictionary, field_name: String, source_path: String) -> float:
	var value: float = _read_number(data, field_name, source_path)
	if not _last_error.is_empty():
		return 0.0
	if value < 0.0:
		_set_error("Definition '%s' requires a non-negative number field named '%s'." % [source_path, field_name])
		return 0.0
	return value


func _read_number(data: Dictionary, field_name: String, source_path: String) -> float:
	var raw_value: Variant = data.get(field_name)
	if typeof(raw_value) != TYPE_INT and typeof(raw_value) != TYPE_FLOAT:
		_set_error("Definition '%s' requires a number field named '%s'." % [source_path, field_name])
		return 0.0
	return float(raw_value)


func _read_required_bool(data: Dictionary, field_name: String, source_path: String) -> bool:
	var raw_value: Variant = data.get(field_name)
	if typeof(raw_value) != TYPE_BOOL:
		_set_error("Definition '%s' requires a boolean field named '%s'." % [source_path, field_name])
		return false
	return bool(raw_value)


func _read_item_amounts(data: Dictionary, field_name: String, source_path: String) -> Dictionary[StringName, int]:
	var raw_amounts: Variant = data.get(field_name)
	if not raw_amounts is Dictionary:
		_set_error("Definition '%s' requires an object field named '%s'." % [source_path, field_name])
		return {}
	if raw_amounts.is_empty():
		_set_error("Definition '%s' requires at least one '%s' entry." % [source_path, field_name])
		return {}

	var amounts: Dictionary[StringName, int] = {}
	for raw_item_id: Variant in raw_amounts:
		if typeof(raw_item_id) != TYPE_STRING:
			_set_error("Definition '%s' has a non-string item ID in '%s'." % [source_path, field_name])
			return {}
		var item_id: StringName = StringName(raw_item_id)
		var validation_error: String = IdValidator.get_validation_error(item_id)
		if not validation_error.is_empty() or not String(item_id).begins_with("item_"):
			_set_error("Definition '%s' has an invalid item ID '%s' in '%s'." % [source_path, String(raw_item_id), field_name])
			return {}
		var raw_amount: Variant = raw_amounts[raw_item_id]
		if typeof(raw_amount) != TYPE_INT and typeof(raw_amount) != TYPE_FLOAT:
			_set_error("Definition '%s' requires a positive integer cost for '%s'." % [source_path, String(item_id)])
			return {}
		var amount: float = float(raw_amount)
		if amount <= 0.0 or amount != floor(amount):
			_set_error("Definition '%s' requires a positive integer cost for '%s'." % [source_path, String(item_id)])
			return {}
		amounts[item_id] = int(amount)

	return amounts


func _set_error(message: String) -> void:
	_last_error = message
