class_name GameText
extends RefCounted

## Central access point for player-facing text. Text keys are stable; locales can be
## added as translation resources without changing game state, definitions, or UI code.

const DEFAULT_LOCALE: String = "zh_CN"


static func initialize() -> void:
	TranslationServer.set_locale(DEFAULT_LOCALE)


static func set_locale(locale: String) -> void:
	TranslationServer.set_locale(locale if not locale.is_empty() else DEFAULT_LOCALE)


static func get_text(key: StringName) -> String:
	return TranslationServer.translate(String(key)).replace("\\n", "\n")


static func format(key: StringName, values: Array[Variant]) -> String:
	return get_text(key) % values
