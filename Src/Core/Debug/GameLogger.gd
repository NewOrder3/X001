class_name GameLogger
extends RefCounted

static func info(category: StringName, message: String) -> void:
	print("[%s] %s" % [String(category), message])

static func warning(category: StringName, message: String) -> void:
	push_warning("[%s] %s" % [String(category), message])

static func error(category: StringName, message: String) -> void:
	push_error("[%s] %s" % [String(category), message])

static func assert_or_log(condition: bool, category: StringName, message: String) -> bool:
	if condition:
		return true
	error(category, message)
	return false
