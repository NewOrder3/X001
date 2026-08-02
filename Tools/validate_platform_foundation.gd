extends SceneTree

func _init() -> void:
	var responsive: ResponsiveUI = ResponsiveUI.new()
	responsive.update_for_width(800.0)
	if responsive.get_layout_profile() != &"phone":
		_fail("Responsive UI did not select phone profile.")
		return
	var quality: QualitySettings = QualitySettings.new()
	var low: PerformanceProfile = quality.apply_profile(&"low")
	if low.particle_multiplier >= 1.0 or low.effects_enabled:
		_fail("Low quality profile did not reduce visual load.")
		return
	print("Platform foundation validation passed.")
	quit(0)

func _fail(message: String) -> void:
	printerr("PLATFORM: %s" % message)
	quit(1)
