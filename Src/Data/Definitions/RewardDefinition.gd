class_name RewardDefinition
extends RefCounted

## Immutable reward package granted after a completed battle.

var id: StringName
var item_rewards: Dictionary[StringName, int]
var survivor_experience: int


func _init(
	new_id: StringName,
	new_item_rewards: Dictionary[StringName, int],
	new_survivor_experience: int,
) -> void:
	id = new_id
	item_rewards = new_item_rewards.duplicate()
	survivor_experience = new_survivor_experience
