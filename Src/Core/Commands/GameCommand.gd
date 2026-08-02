class_name GameCommand
extends RefCounted

## Immutable request data. Concrete commands provide their stable command type.

func get_command_type() -> StringName:
	return &""
