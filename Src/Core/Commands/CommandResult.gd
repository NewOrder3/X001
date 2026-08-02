class_name CommandResult
extends RefCounted

## Explicit result returned by a command handler after validation and execution.

var succeeded: bool
var error_code: StringName
var message: String


func _init(new_succeeded: bool, new_error_code: StringName, new_message: String) -> void:
	succeeded = new_succeeded
	error_code = new_error_code
	message = new_message


static func success(message_text: String = "") -> CommandResult:
	return CommandResult.new(true, &"", message_text)


static func failure(error: StringName, message_text: String) -> CommandResult:
	return CommandResult.new(false, error, message_text)
