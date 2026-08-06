## Shared domain-event container owned by SessionCommandSystem.
## The signals are intentionally emitted and connected from other classes
## (SessionCommandSystem, SceneRouter, tests, tools), so the unused_signal
## static-analysis warning does not apply to this class.
@warning_ignore("unused_signal")
class_name SessionEvents
extends RefCounted

## Events emitted by SessionCommandSystem after a command has changed session state.

signal new_game_created(world_seed: int)
signal command_rejected(command_type: StringName, error_code: StringName)
signal battle_started(boss_id: StringName)
signal battle_exited()
