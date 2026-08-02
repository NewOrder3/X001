class_name X001TestCase
extends RefCounted

## Minimal zero-dependency test base used by Tools/run_tests.gd.

var _failures: Array[String] = []


func assert_true(condition: bool, message: String = "") -> void:
	if condition:
		return
	_record_failure(_message_or_default(message, "Expected condition to be true."))


func assert_false(condition: bool, message: String = "") -> void:
	if not condition:
		return
	_record_failure(_message_or_default(message, "Expected condition to be false."))


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if actual == expected:
		return
	_record_failure(
		_message_or_default(message, "Expected '%s', got '%s'." % [str(expected), str(actual)])
	)


func assert_not_null(value: Variant, message: String = "") -> void:
	if value != null:
		return
	_record_failure(_message_or_default(message, "Expected value not to be null."))


func assert_null(value: Variant, message: String = "") -> void:
	if value == null:
		return
	_record_failure(_message_or_default(message, "Expected value to be null."))


func get_failures() -> Array[String]:
	return _failures.duplicate()


func clear_failures() -> void:
	_failures.clear()


func _record_failure(message: String) -> void:
	_failures.append(message)


func _message_or_default(message: String, default_message: String) -> String:
	if not message.is_empty():
		return message
	return default_message
