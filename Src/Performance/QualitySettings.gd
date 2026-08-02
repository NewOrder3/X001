class_name QualitySettings
extends RefCounted

const LOW: StringName = &"low"
const MEDIUM: StringName = &"medium"
const HIGH: StringName = &"high"

var _profile: PerformanceProfile = PerformanceProfile.new(HIGH, 1.0, 1.0, true)

func apply_profile(profile: StringName) -> PerformanceProfile:
	if profile == LOW:
		_profile = PerformanceProfile.new(LOW, 0.25, 0.5, false)
	elif profile == MEDIUM:
		_profile = PerformanceProfile.new(MEDIUM, 0.6, 0.75, true)
	else:
		_profile = PerformanceProfile.new(HIGH, 1.0, 1.0, true)
	return _profile

func get_profile() -> PerformanceProfile:
	return _profile
