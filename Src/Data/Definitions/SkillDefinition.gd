class_name SkillDefinition
extends RefCounted

## Immutable battle skill description used by survivor cards.

enum EffectType {
	DAMAGE,
	HEAL,
}

var id: StringName
var display_name_key: StringName
var description_key: StringName
var effect_type: EffectType
var power: int
var cooldown_turns: int


func _init(
	new_id: StringName,
	new_display_name_key: StringName,
	new_description_key: StringName,
	new_effect_type: EffectType,
	new_power: int,
	new_cooldown_turns: int,
) -> void:
	id = new_id
	display_name_key = new_display_name_key
	description_key = new_description_key
	effect_type = new_effect_type
	power = new_power
	cooldown_turns = new_cooldown_turns


func get_display_name() -> String:
	return GameText.get_text(display_name_key)


func get_description() -> String:
	return GameText.get_text(description_key)
