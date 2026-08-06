class_name BattleActionResult
extends RefCounted

var succeeded: bool = false
var error_code: StringName = &""
var message: String = ""
var battle_completed: bool = false
var did_win: bool = false


static func success(new_message: String, completed: bool = false, won: bool = false) -> BattleActionResult:
	var result: BattleActionResult = BattleActionResult.new()
	result.succeeded = true
	result.message = new_message
	result.battle_completed = completed
	result.did_win = won
	return result


static func failure(new_error_code: StringName, new_message: String) -> BattleActionResult:
	var result: BattleActionResult = BattleActionResult.new()
	result.error_code = new_error_code
	result.message = new_message
	return result
