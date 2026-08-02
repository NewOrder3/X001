class_name ResponsiveUI
extends Control

const DESKTOP_PROFILE: StringName = &"desktop"
const TABLET_PROFILE: StringName = &"tablet"
const PHONE_PROFILE: StringName = &"phone"

var _profile: StringName = DESKTOP_PROFILE

func apply_layout_profile(profile: StringName) -> void:
	_profile = profile

func update_for_width(content_width: float) -> void:
	if content_width < 900.0:
		apply_layout_profile(PHONE_PROFILE)
	elif content_width < 1400.0:
		apply_layout_profile(TABLET_PROFILE)
	else:
		apply_layout_profile(DESKTOP_PROFILE)

func get_layout_profile() -> StringName:
	return _profile
