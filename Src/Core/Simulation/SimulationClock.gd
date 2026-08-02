class_name SimulationClock
extends RefCounted

signal simulation_tick(delta_seconds: float)

const TICKS_PER_SECOND: float = 5.0
const TICK_INTERVAL_SECONDS: float = 1.0 / TICKS_PER_SECOND
const MAX_CATCH_UP_TICKS: int = 8
const ALLOWED_SPEEDS: Array[float] = [0.0, 1.0, 2.0, 4.0]

var _is_running: bool = false
var _speed: float = 1.0
var _accumulated_seconds: float = 0.0


func start() -> void:
	_is_running = true


func pause() -> void:
	_is_running = false


func set_speed(multiplier: float) -> bool:
	if not ALLOWED_SPEEDS.has(multiplier):
		push_error("SIMULATION: Unsupported speed multiplier %s." % multiplier)
		return false
	_speed = multiplier
	return true


func advance(delta: float) -> int:
	if not _is_running or _speed <= 0.0 or delta <= 0.0:
		return 0

	_accumulated_seconds += delta * _speed
	var emitted_tick_count: int = 0
	while _accumulated_seconds >= TICK_INTERVAL_SECONDS and emitted_tick_count < MAX_CATCH_UP_TICKS:
		_accumulated_seconds -= TICK_INTERVAL_SECONDS
		emitted_tick_count += 1
		simulation_tick.emit(TICK_INTERVAL_SECONDS)

	if emitted_tick_count == MAX_CATCH_UP_TICKS and _accumulated_seconds >= TICK_INTERVAL_SECONDS:
		_accumulated_seconds = TICK_INTERVAL_SECONDS

	return emitted_tick_count


func get_speed() -> float:
	return _speed


func is_running() -> bool:
	return _is_running
