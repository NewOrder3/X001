class_name SessionEvents
extends RefCounted

## Events emitted by SessionCommandSystem after a command has changed session state.

signal new_game_created(world_seed: int)
signal command_rejected(command_type: StringName, error_code: StringName)
