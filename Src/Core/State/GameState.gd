class_name GameState
extends RefCounted

## Stores one game's mutable state. Gameplay rules belong to Systems, not this class.

var world_seed: int
var raft_state: RaftState
var inventory_state: InventoryState
var survivor_state: SurvivorState
var world_state: WorldState
var battle_state: BattleState
var progression_state: ProgressionState


func _init(initial_world_seed: int = 0) -> void:
	world_seed = initial_world_seed
	raft_state = RaftState.new()
	inventory_state = InventoryState.new()
	survivor_state = SurvivorState.new()
	world_state = WorldState.new()
	battle_state = BattleState.new()
	progression_state = ProgressionState.new()
