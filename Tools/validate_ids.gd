extends SceneTree


func _init() -> void:
	var raw_ids: PackedStringArray = OS.get_cmdline_user_args()
	if raw_ids.is_empty():
		printerr("Usage: godot --headless --path . --script res://Tools/validate_ids.gd -- <stable_id> [...]")
		quit(2)
		return

	var ids: Array[StringName] = []
	var has_error: bool = false
	for raw_id: String in raw_ids:
		var id: StringName = StringName(raw_id)
		var validation_error: String = IdValidator.get_validation_error(id)
		if not validation_error.is_empty():
			printerr("Invalid ID '%s': %s" % [raw_id, validation_error])
			has_error = true
		ids.append(id)

	var duplicate_ids: Array[StringName] = IdValidator.find_duplicate_ids(ids)
	for duplicate_id: StringName in duplicate_ids:
		printerr("Duplicate ID: '%s'" % String(duplicate_id))
		has_error = true

	if has_error:
		quit(1)
		return

	print("Validated %d stable ID(s)." % ids.size())
	quit(0)
