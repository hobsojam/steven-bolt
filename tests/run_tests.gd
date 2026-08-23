extends SceneTree

const RunRules := preload("res://scripts/run_rules.gd")

var _failures: int = 0


func _initialize() -> void:
	_test_apply_gate_addition()
	_test_apply_gate_subtraction()
	_test_apply_gate_underflow_clamps_to_zero()
	_test_apply_gate_exact_zero()
	_test_apply_gate_stacking()
	_test_lane_x_symmetry()
	_test_crowd_layout_empty_for_zero()
	_test_crowd_layout_caps_at_max_rendered()
	_test_crowd_layout_stays_within_max_width()
	_test_can_pass_toll_true_when_sufficient()
	_test_can_pass_toll_false_when_insufficient()
	_test_apply_toll_consumes_threshold()

	if _failures == 0:
		print("All tests passed")
		quit(0)
	else:
		push_error("%d test failure(s)" % _failures)
		quit(1)


func _test_apply_gate_addition() -> void:
	_assert_eq(RunRules.apply_gate(20, "+", 10), 30, "addition increases count")


func _test_apply_gate_subtraction() -> void:
	_assert_eq(RunRules.apply_gate(20, "-", 5), 15, "subtraction decreases count")


func _test_apply_gate_underflow_clamps_to_zero() -> void:
	_assert_eq(RunRules.apply_gate(10, "-", 25), 0, "subtraction below zero clamps to zero")


func _test_apply_gate_exact_zero() -> void:
	_assert_eq(RunRules.apply_gate(10, "-", 10), 0, "subtraction to exactly zero stays zero")


func _test_apply_gate_stacking() -> void:
	var count: int = RunRules.START_CROWD_COUNT
	count = RunRules.apply_gate(count, "+", 10)
	count = RunRules.apply_gate(count, "-", 5)
	count = RunRules.apply_gate(count, "+", 100)
	_assert_eq(count, RunRules.START_CROWD_COUNT + 10 - 5 + 100, "stacked gates apply in order")


func _test_lane_x_symmetry() -> void:
	var leftmost: float = RunRules.lane_x(0)
	var rightmost: float = RunRules.lane_x(RunRules.LANE_COUNT - 1)
	_assert_eq(leftmost, -rightmost, "lane positions are symmetric around the track centerline")


func _test_crowd_layout_empty_for_zero() -> void:
	_assert_eq(RunRules.crowd_layout(0).size(), 0, "zero crowd renders no instances")


func _test_crowd_layout_caps_at_max_rendered() -> void:
	_assert_eq(
		RunRules.crowd_layout(500).size(),
		RunRules.MAX_RENDERED_UNITS,
		"instance count caps at MAX_RENDERED_UNITS"
	)


func _test_crowd_layout_stays_within_max_width() -> void:
	var positions: Array[Vector3] = RunRules.crowd_layout(RunRules.MAX_RENDERED_UNITS)
	var max_abs_x: float = 0.0
	for pos in positions:
		max_abs_x = maxf(max_abs_x, absf(pos.x))
	_assert_true(
		max_abs_x <= RunRules.CROWD_MAX_WIDTH / 2.0 + 0.01,
		"crowd width stays within the clamped track width"
	)


func _test_can_pass_toll_true_when_sufficient() -> void:
	_assert_true(RunRules.can_pass_toll(100, 60), "sufficient crowd passes the toll check")


func _test_can_pass_toll_false_when_insufficient() -> void:
	_assert_true(not RunRules.can_pass_toll(40, 60), "insufficient crowd fails the toll check")


func _test_apply_toll_consumes_threshold() -> void:
	_assert_eq(RunRules.apply_toll(100, 60), 40, "toll wall consumes exactly the threshold amount")


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("FAIL: %s" % message)
	else:
		print("PASS: %s" % message)


func _assert_eq(actual, expected, message: String) -> void:
	if actual != expected:
		_failures += 1
		push_error("FAIL: %s (expected %s, got %s)" % [message, expected, actual])
	else:
		print("PASS: %s" % message)
