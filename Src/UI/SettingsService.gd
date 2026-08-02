class_name SettingsService
extends RefCounted

var _state: SettingsState = SettingsState.new()

func get_state() -> SettingsState:
	return _state

func set_text_scale(value: float) -> void:
	_state.text_scale = clampf(value, 0.8, 1.5)

func set_master_volume(value: float) -> void:
	_state.master_volume = clampf(value, 0.0, 1.0)

func set_screen_shake_enabled(value: bool) -> void:
	_state.screen_shake_enabled = value
