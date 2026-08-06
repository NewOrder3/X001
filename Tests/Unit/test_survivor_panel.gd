extends "res://Tests/TestCase.gd"


func test_portrait_uses_a_theme_override_supported_by_button() -> void:
	var panel: SurvivorPanel = SurvivorPanel.new()
	var button: Button = Button.new()
	panel._apply_portrait(button, &"survivor_bo")

	assert_not_null(button.icon)
	assert_eq(button.get_theme_constant(&"icon_max_width"), 42)
	button.free()
	panel.free()
