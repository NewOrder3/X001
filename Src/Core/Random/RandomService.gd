class_name RandomService
extends RefCounted

const DEFAULT_STREAM_ID: StringName = &"world"

var _world_seed: int = 0
var _streams: Dictionary[StringName, RandomNumberGenerator] = {}


func set_world_seed(seed: int) -> void:
	_world_seed = seed
	_streams.clear()


func get_stream(stream_id: StringName) -> RandomNumberGenerator:
	if not _streams.has(stream_id):
		var stream: RandomNumberGenerator = RandomNumberGenerator.new()
		stream.seed = _derive_seed(stream_id)
		_streams[stream_id] = stream
	return _streams[stream_id]


func roll_chance(chance: float) -> bool:
	if chance <= 0.0:
		return false
	if chance >= 1.0:
		return true
	return get_stream(DEFAULT_STREAM_ID).randf() < chance


func range_i(minimum: int, maximum: int) -> int:
	assert(minimum <= maximum, "RandomService range minimum must not exceed maximum.")
	return get_stream(DEFAULT_STREAM_ID).randi_range(minimum, maximum)


func get_world_seed() -> int:
	return _world_seed


func _derive_seed(stream_id: StringName) -> int:
	var hash_value: int = 2166136261
	for character: String in String(stream_id):
		hash_value = int((hash_value ^ character.unicode_at(0)) * 16777619)
	return _world_seed ^ hash_value
