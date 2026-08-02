extends SceneTree

const SANDBOX_PATHS: Array[String] = [
	"res://Scenes/Dev/GridSandbox.tscn",
	"res://Scenes/Dev/BuildingSandbox.tscn",
	"res://Scenes/Dev/HexMapSandbox.tscn",
	"res://Scenes/Dev/BattleSandbox.tscn",
	"res://Scenes/Dev/UISandbox.tscn",
	"res://Scenes/Dev/DebugPanel.tscn",
]


func _init() -> void:
	for sandbox_path: String in SANDBOX_PATHS:
		var packed_scene: PackedScene = load(sandbox_path) as PackedScene
		if packed_scene == null:
			_fail("Could not load sandbox '%s'." % sandbox_path)
			return
		var sandbox_root: Node = packed_scene.instantiate()
		if not sandbox_root.has_meta(&"sandbox_status"):
			_fail("Sandbox '%s' is missing sandbox_status metadata." % sandbox_path)
			return
		if not sandbox_root.has_meta(&"sandbox_next_stage"):
			_fail("Sandbox '%s' is missing sandbox_next_stage metadata." % sandbox_path)
			return
		sandbox_root.free()

	print("Sandbox status validation passed.")
	quit(0)


func _fail(message: String) -> void:
	printerr("SANDBOX: %s" % message)
	quit(1)
