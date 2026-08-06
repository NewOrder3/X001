class_name QuestDefinition
extends RefCounted

## Immutable new-player goal template. Progress is derived from GameState; only
## completion flags and defeated bosses are persisted in QuestState.

enum ObjectiveType {
	BUILD_BUILDING,
	HAVE_ITEM,
	UPGRADE_RAFT,
	RECRUIT_SURVIVOR,
	WIN_BATTLE,
	EXPLORE_REGION,
	USE_ITEM,
}

var id: StringName
var display_name_key: StringName
var description_key: StringName
var objective_type: ObjectiveType
var target_id: StringName
var target_amount: int
var sort_order: int
var prerequisite_quest_ids: Array[StringName]


func _init(
	new_id: StringName,
	new_display_name_key: StringName,
	new_description_key: StringName,
	new_objective_type: ObjectiveType,
	new_target_id: StringName,
	new_target_amount: int,
	new_sort_order: int,
	new_prerequisite_quest_ids: Array[StringName],
) -> void:
	id = new_id
	display_name_key = new_display_name_key
	description_key = new_description_key
	objective_type = new_objective_type
	target_id = new_target_id
	target_amount = new_target_amount
	sort_order = new_sort_order
	prerequisite_quest_ids = new_prerequisite_quest_ids.duplicate()


func get_display_name() -> String:
	return GameText.get_text(display_name_key)


func get_description() -> String:
	return GameText.get_text(description_key)
