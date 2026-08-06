class_name BossDefinition
extends RefCounted

## Immutable opponent data. Runtime health belongs to BattleState.

var id: StringName
var display_name_key: StringName
var description_key: StringName
var max_health: int
var attack_damage: int
var reward_id: StringName
var unlock_id: StringName
var victory_durability_loss: float
var defeat_durability_loss: float


func _init(
	new_id: StringName,
	new_display_name_key: StringName,
	new_description_key: StringName,
	new_max_health: int,
	new_attack_damage: int,
	new_reward_id: StringName,
	new_victory_durability_loss: float,
	new_defeat_durability_loss: float,
	new_unlock_id: StringName = &"",
) -> void:
	id = new_id
	display_name_key = new_display_name_key
	description_key = new_description_key
	max_health = new_max_health
	attack_damage = new_attack_damage
	reward_id = new_reward_id
	victory_durability_loss = new_victory_durability_loss
	defeat_durability_loss = new_defeat_durability_loss
	unlock_id = new_unlock_id


func get_display_name() -> String:
	return GameText.get_text(display_name_key)
