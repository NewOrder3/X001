extends SceneTree


func _init() -> void:
	var registry: DataRegistry = DataRegistry.new()
	if not registry.load_all():
		printerr("DATA: %s" % registry.get_last_error())
		quit(1)
		return

	print(
		"Loaded %d item Definition(s) and %d building Definition(s)." % [
			registry.get_item_count(),
			registry.get_building_count(),
		]
	)
	quit(0)
