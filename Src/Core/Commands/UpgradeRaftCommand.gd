class_name UpgradeRaftCommand
extends GameCommand

## Requests a raft expansion. ProgressionSystem owns validation, cost and deck growth.


func get_command_type() -> StringName:
	return &"upgrade_raft"
