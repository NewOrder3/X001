extends SceneTree

const TEST_SCRIPTS: Array[String] = [
	"res://Tests/Unit/test_grid_math.gd",
	"res://Tests/Unit/test_hex_grid.gd",
	"res://Tests/Unit/test_raft_grid.gd",
	"res://Tests/Unit/test_random_service.gd",
	"res://Tests/Unit/test_exploration_system.gd",
	"res://Tests/Unit/test_save_service.gd",
	"res://Tests/Unit/test_survival_state.gd",
	"res://Tests/Unit/test_survival_calculator.gd",
	"res://Tests/Unit/test_survival_system.gd",
	"res://Tests/Unit/test_session_command_system.gd",
	"res://Tests/Unit/test_data_registry.gd",
	"res://Tests/Unit/test_building_system.gd",
	"res://Tests/Unit/test_production_system.gd",
	"res://Tests/Unit/test_raft_build_view.gd",
]

var _failed_test_count: int = 0
var _run_test_count: int = 0


func _init() -> void:
	for script_path: String in TEST_SCRIPTS:
		_run_script_tests(script_path)

	if _failed_test_count > 0:
		printerr("TEST: %d of %d test(s) failed." % [_failed_test_count, _run_test_count])
		quit(1)
		return

	print("TEST: %d test(s) passed." % _run_test_count)
	quit(0)


func _run_script_tests(script_path: String) -> void:
	var test_script: Script = load(script_path) as Script
	if test_script == null:
		_record_runner_failure(script_path, "Could not load test script.")
		return

	var test_case: RefCounted = test_script.new() as RefCounted
	if test_case == null:
		_record_runner_failure(script_path, "Test script must extend X001TestCase.")
		return

	var method_names: Array[StringName] = _get_test_method_names(test_case)
	if method_names.is_empty():
		_record_runner_failure(script_path, "Test script has no methods beginning with test_.")
		return

	for method_name: StringName in method_names:
		_run_test_count += 1
		test_case.call(&"clear_failures")
		test_case.call(method_name)
		var raw_failures: Variant = test_case.call(&"get_failures")
		var failures: Array = raw_failures if raw_failures is Array else []
		if failures.is_empty():
			print("PASS: %s::%s" % [script_path, String(method_name)])
			continue

		_failed_test_count += 1
		for failure: Variant in failures:
			printerr("FAIL: %s::%s - %s" % [script_path, String(method_name), str(failure)])


func _get_test_method_names(test_case: RefCounted) -> Array[StringName]:
	var method_names: Array[StringName] = []
	for method_data: Dictionary in test_case.get_method_list():
		var method_name: StringName = method_data.get("name", &"") as StringName
		if String(method_name).begins_with("test_"):
			method_names.append(method_name)
	method_names.sort()
	return method_names


func _record_runner_failure(script_path: String, message: String) -> void:
	_run_test_count += 1
	_failed_test_count += 1
	printerr("FAIL: %s - %s" % [script_path, message])
