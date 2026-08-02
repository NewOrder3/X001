class_name IdValidator
extends RefCounted

## Validates stable Definition and save-reference IDs without depending on data format.

const ALLOWED_PREFIXES: Array[String] = [
	"item",
	"building",
	"recipe",
	"survivor",
	"skill",
	"boss",
	"region",
	"event",
	"quest",
	"progression",
]


static func is_valid_id(id: StringName) -> bool:
	return get_validation_error(id).is_empty()


static func get_validation_error(id: StringName) -> String:
	var value: String = String(id)
	if value.is_empty():
		return "ID must not be empty."

	var segments: PackedStringArray = value.split("_", true)
	if segments.size() < 2:
		return "ID must use the format <prefix>_<name>."

	var prefix: String = segments[0]
	if not ALLOWED_PREFIXES.has(prefix):
		return "Unknown ID prefix '%s'." % prefix

	for segment: String in segments:
		if not _is_valid_segment(segment):
			return "ID segments must begin with a lowercase letter and contain only lowercase ASCII letters or digits."

	return ""


static func find_duplicate_ids(ids: Array[StringName]) -> Array[StringName]:
	var seen_counts: Dictionary[StringName, int] = {}
	var duplicate_ids: Array[StringName] = []

	for id: StringName in ids:
		var count: int = seen_counts.get(id, 0)
		seen_counts[id] = count + 1
		if count == 1:
			duplicate_ids.append(id)

	return duplicate_ids


static func _is_valid_segment(segment: String) -> bool:
	if segment.is_empty():
		return false

	var first_code: int = segment.unicode_at(0)
	if first_code < 97 or first_code > 122:
		return false

	for index: int in range(1, segment.length()):
		var code: int = segment.unicode_at(index)
		var is_lowercase_letter: bool = code >= 97 and code <= 122
		var is_digit: bool = code >= 48 and code <= 57
		if not is_lowercase_letter and not is_digit:
			return false

	return true
