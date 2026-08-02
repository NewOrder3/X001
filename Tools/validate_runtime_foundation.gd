extends SceneTree

var _tick_count: int = 0


func _init() -> void:
	var clock: SimulationClock = SimulationClock.new()
	clock.simulation_tick.connect(_on_simulation_tick)
	clock.start()
	if clock.advance(1.0) != 5 or _tick_count != 5:
		_fail("SimulationClock did not emit five ticks in one second.")
		return
	clock.pause()
	if clock.advance(1.0) != 0:
		_fail("SimulationClock advanced while paused.")
		return
	clock.start()
	clock.set_speed(2.0)
	if clock.advance(0.5) != 5:
		_fail("SimulationClock 2x speed was incorrect.")
		return

	var first_random: RandomService = RandomService.new()
	var second_random: RandomService = RandomService.new()
	first_random.set_world_seed(77)
	second_random.set_world_seed(77)
	if first_random.range_i(1, 1000) != second_random.range_i(1, 1000):
		_fail("RandomService was not deterministic for the same seed.")
		return
	first_random.get_stream(&"event").randi()
	if first_random.range_i(1, 1000) != second_random.range_i(1, 1000):
		_fail("Random streams were not isolated.")
		return

	var save_service: SaveService = SaveService.new()
	save_service.new_game(999)
	if not save_service.save_game(&"framework_validation"):
		_fail(save_service.get_last_error())
		return
	var loaded_state: GameState = save_service.load_game(&"framework_validation")
	if loaded_state == null or loaded_state.world_seed != 999:
		_fail("SaveService did not restore the saved GameState.")
		return

	print("Runtime foundation validation passed.")
	quit(0)


func _on_simulation_tick(_delta_seconds: float) -> void:
	_tick_count += 1


func _fail(message: String) -> void:
	printerr("RUNTIME: %s" % message)
	quit(1)
