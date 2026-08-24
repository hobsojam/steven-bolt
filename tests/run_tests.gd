extends SceneTree

const RunRules := preload("res://scripts/run_rules.gd")
const ChaseCamera := preload("res://scripts/chase_camera.gd")
const LevelOneDefinition := preload("res://scripts/level_one_definition.gd")
const CombatRules := preload("res://scripts/combat_rules.gd")
const EnemyWaveRuntime := preload("res://scripts/enemy_wave_runtime.gd")
const RivalCrowdRules := preload("res://scripts/rival_crowd_rules.gd")
const RivalCrowdRuntime := preload("res://scripts/rival_crowd_runtime.gd")

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
	_test_crowd_layout_stays_shallower_than_camera_offset()
	_test_crowd_layout_stays_within_max_depth()
	_test_crowd_layout_stays_narrow_at_start_count()
	_test_crowd_unit_scale_full_size_for_one()
	_test_crowd_unit_scale_drops_per_doubling()
	_test_crowd_unit_scale_is_monotonic()
	_test_can_pass_toll_true_when_sufficient()
	_test_can_pass_toll_false_when_insufficient()
	_test_apply_toll_consumes_threshold()
	_test_current_speed_ramps_up_over_time()
	_test_current_speed_caps_at_max()
	_test_expand_pickup_trail_generates_correct_points()
	_test_expand_pickup_trail_points_carry_lane_and_value()
	_test_entries_are_sorted_by_distance()
	_test_entries_contain_a_partial_enemy_wave()
	_test_entries_contain_a_rival_crowd_before_finish()
	_test_shot_damage_scales_with_crowd_count()
	_test_nearest_enemy_index_in_lane_picks_closest()
	_test_apply_hit_kills_at_zero_hp()
	_test_try_fire_and_resolve_hits_kills_enemy()
	_test_resolve_breaches_costs_only_alive_crossed_enemies()
	_test_rival_crowd_many_small_ticks_accumulate_nonzero_loss()
	_test_rival_crowd_tick_never_exceeds_smaller_count()
	_test_rival_crowd_is_defeated_at_zero()
	_test_rival_crowd_resolves_to_absolute_difference()
	_test_rival_crowd_tick_does_nothing_once_defeated()
	_test_build_multimesh_transforms_matches_crowd_layout_count()
	_test_apply_shot_damage_reduces_and_clamps_at_zero()
	_test_apply_shot_damage_is_cooldown_gated()
	_test_apply_shot_damage_then_tick_carries_count_across_phases()

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


func _test_crowd_layout_stays_shallower_than_camera_offset() -> void:
	var positions: Array[Vector3] = RunRules.crowd_layout(RunRules.MAX_RENDERED_UNITS)
	var max_depth: float = 0.0
	for pos in positions:
		max_depth = maxf(max_depth, pos.z)
	_assert_true(
		max_depth < ChaseCamera.BACK_OFFSET,
		"crowd depth at the render cap stays inside the chase camera's follow distance"
	)


func _test_crowd_layout_stays_within_max_depth() -> void:
	var positions: Array[Vector3] = RunRules.crowd_layout(RunRules.MAX_RENDERED_UNITS)
	var max_depth: float = 0.0
	for pos in positions:
		max_depth = maxf(max_depth, pos.z)
	_assert_true(
		max_depth <= RunRules.CROWD_MAX_DEPTH,
		"crowd depth at the render cap stays within CROWD_MAX_DEPTH"
	)


func _test_crowd_layout_stays_narrow_at_start_count() -> void:
	var positions: Array[Vector3] = RunRules.crowd_layout(RunRules.START_CROWD_COUNT)
	var max_abs_x: float = 0.0
	for pos in positions:
		max_abs_x = maxf(max_abs_x, absf(pos.x))
	_assert_true(
		max_abs_x < RunRules.CROWD_MAX_WIDTH / 2.0,
		"crowd stays narrower than the full clamped width at the starting crowd count"
	)


func _test_crowd_unit_scale_full_size_for_one() -> void:
	_assert_eq(RunRules.crowd_unit_scale(1), 1.0, "a single crowd unit renders at full size")


func _test_crowd_unit_scale_drops_per_doubling() -> void:
	_assert_true(
		absf(RunRules.crowd_unit_scale(2) - RunRules.CROWD_SCALE_PER_DOUBLING) < 0.001,
		"scale drops by CROWD_SCALE_PER_DOUBLING the first time the crowd doubles"
	)
	_assert_true(
		(
			absf(
				RunRules.crowd_unit_scale(4)
				- RunRules.CROWD_SCALE_PER_DOUBLING * RunRules.CROWD_SCALE_PER_DOUBLING
			)
			< 0.001
		),
		"scale compounds by CROWD_SCALE_PER_DOUBLING again by the second doubling"
	)


func _test_crowd_unit_scale_is_monotonic() -> void:
	_assert_true(
		RunRules.crowd_unit_scale(50) > RunRules.crowd_unit_scale(120),
		"crowd units keep shrinking as count grows"
	)


func _test_can_pass_toll_true_when_sufficient() -> void:
	_assert_true(RunRules.can_pass_toll(100, 60), "sufficient crowd passes the toll check")


func _test_can_pass_toll_false_when_insufficient() -> void:
	_assert_true(not RunRules.can_pass_toll(40, 60), "insufficient crowd fails the toll check")


func _test_apply_toll_consumes_threshold() -> void:
	_assert_eq(RunRules.apply_toll(100, 60), 40, "toll wall consumes exactly the threshold amount")


func _test_current_speed_ramps_up_over_time() -> void:
	_assert_true(
		RunRules.current_speed(10.0) > RunRules.current_speed(0.0),
		"run speed increases as elapsed time increases"
	)


func _test_current_speed_caps_at_max() -> void:
	_assert_eq(
		RunRules.current_speed(10000.0),
		RunRules.MAX_RUN_SPEED,
		"run speed never exceeds MAX_RUN_SPEED"
	)


func _test_expand_pickup_trail_generates_correct_points() -> void:
	var trail := {
		"lane": 2,
		"start_distance": 10.0,
		"end_distance": 20.0,
		"spacing": 5.0,
		"op": "+",
		"value": 3,
	}
	var pickups: Array[Dictionary] = LevelOneDefinition.expand_pickup_trail(trail)
	_assert_eq(pickups.size(), 3, "pickup trail generates one point per spacing interval")
	_assert_eq(pickups[0]["distance"], 10.0, "first pickup sits at the trail's start distance")
	_assert_eq(pickups[2]["distance"], 20.0, "last pickup sits at the trail's end distance")


func _test_expand_pickup_trail_points_carry_lane_and_value() -> void:
	var trail := {
		"lane": 1,
		"start_distance": 0.0,
		"end_distance": 0.0,
		"spacing": 1.0,
		"op": "-",
		"value": 7,
	}
	var pickups: Array[Dictionary] = LevelOneDefinition.expand_pickup_trail(trail)
	_assert_eq(pickups.size(), 1, "a zero-length trail still yields its single start point")
	_assert_eq(pickups[0]["kind"], "pickup", 'expanded points are kind "pickup"')
	_assert_eq(pickups[0]["lane"], 1, "expanded points carry the trail's lane")
	_assert_eq(pickups[0]["op"], "-", "expanded points carry the trail's op")
	_assert_eq(pickups[0]["value"], 7, "expanded points carry the trail's value")


func _test_entries_are_sorted_by_distance() -> void:
	var all_entries: Array[Dictionary] = LevelOneDefinition.entries()
	for i in range(1, all_entries.size()):
		_assert_true(
			all_entries[i - 1]["distance"] <= all_entries[i]["distance"],
			"level entries stay sorted by distance after pickup-trail expansion"
		)


func _test_entries_contain_a_partial_enemy_wave() -> void:
	var wave: Dictionary = {}
	for entry in LevelOneDefinition.entries():
		if entry["kind"] == "enemy_wave":
			wave = entry
			break
	_assert_true(not wave.is_empty(), "the level has an enemy_wave entry")
	_assert_true(wave["enemies"].size() > 0, "the enemy wave has at least one enemy")
	var threatened_lanes: Array = []
	for enemy in wave["enemies"]:
		if not threatened_lanes.has(enemy["lane"]):
			threatened_lanes.append(enemy["lane"])
	_assert_true(
		threatened_lanes.size() < RunRules.LANE_COUNT,
		"the wave doesn't put an enemy in every lane"
	)


func _test_entries_contain_a_rival_crowd_before_finish() -> void:
	var rival: Dictionary = {}
	for entry in LevelOneDefinition.entries():
		if entry["kind"] == "rival_crowd":
			rival = entry
			break
	_assert_true(not rival.is_empty(), "the level has a rival_crowd entry")
	_assert_true(rival["count"] > 0, "the rival crowd starts with a positive count")
	_assert_true(
		LevelOneDefinition.length() - rival["distance"] >= 10.0,
		"the rival crowd has at least some runway before the finish line"
	)


func _test_shot_damage_scales_with_crowd_count() -> void:
	_assert_eq(CombatRules.shot_damage(0), 1, "shot damage has a floor of 1 with no crowd")
	_assert_true(
		CombatRules.shot_damage(200) > CombatRules.shot_damage(20),
		"shot damage increases as crowd count grows"
	)


func _test_nearest_enemy_index_in_lane_picks_closest() -> void:
	var runtime := EnemyWaveRuntime.new(
		[
			{"lane": 0, "distance": 30.0, "hp": 1},
			{"lane": 0, "distance": 10.0, "hp": 1},
			{"lane": 1, "distance": 5.0, "hp": 1},
		]
	)
	_assert_eq(
		runtime.nearest_enemy_index_in_lane(0), 1, "picks the closer of two enemies in the lane"
	)
	_assert_eq(runtime.nearest_enemy_index_in_lane(2), -1, "returns -1 when a lane has no enemy")


func _test_apply_hit_kills_at_zero_hp() -> void:
	var runtime := EnemyWaveRuntime.new([{"lane": 0, "distance": 10.0, "hp": 2}])
	_assert_true(not runtime.apply_hit(0, 1), "a hit that leaves hp above zero does not kill")
	_assert_true(runtime.apply_hit(0, 1), "a hit that drops hp to zero kills")


func _test_try_fire_and_resolve_hits_kills_enemy() -> void:
	var runtime := EnemyWaveRuntime.new([{"lane": 0, "distance": 10.0, "hp": 1}])
	runtime.try_fire(0, 0.0, 1, 1.0)
	_assert_eq(runtime.bullets.size(), 1, "a target in range fires a bullet")
	runtime.advance_bullets(1.0)
	var killed: Array[int] = runtime.resolve_hits()
	_assert_eq(killed, [0], "a bullet that reaches the enemy's distance kills it")
	_assert_true(runtime.is_cleared(), "the wave is cleared once its only enemy is killed")


func _test_resolve_breaches_costs_only_alive_crossed_enemies() -> void:
	var runtime := EnemyWaveRuntime.new(
		[
			{"lane": 0, "distance": 5.0, "hp": 1},
			{"lane": 1, "distance": 20.0, "hp": 1},
		]
	)
	runtime.apply_hit(0, 1)
	runtime.enemies.append({"lane": 2, "distance": 3.0, "hp": 1, "alive": true})
	var cost: int = runtime.resolve_breaches(10.0)
	_assert_eq(
		cost,
		CombatRules.ENEMY_BREACH_COST,
		"breach cost only counts the alive enemy whose distance was crossed"
	)


func _test_rival_crowd_many_small_ticks_accumulate_nonzero_loss() -> void:
	var runtime := RivalCrowdRuntime.new(1000)
	var total_loss: int = 0
	for i in 60:
		total_loss += runtime.tick(1.0 / 60.0, 1000)
	_assert_true(
		total_loss > 0,
		"many small ticks accumulate to a nonzero loss instead of truncating to 0 forever"
	)
	_assert_true(
		absi(total_loss - RivalCrowdRules.LOSS_RATE_PER_SECOND) <= 1,
		"accumulated loss over one second matches the per-second rate closely"
	)


func _test_rival_crowd_tick_never_exceeds_smaller_count() -> void:
	var runtime := RivalCrowdRuntime.new(30)
	var loss: int = runtime.tick(10.0, 100)
	_assert_true(loss <= 30, "a single tick never loses more than the smaller side's count")
	_assert_eq(runtime.rival_count, 0, "a large enough delta fully resolves the smaller side")


func _test_rival_crowd_is_defeated_at_zero() -> void:
	var runtime := RivalCrowdRuntime.new(10)
	_assert_true(not runtime.is_defeated(), "a rival crowd with units left is not defeated")
	runtime.tick(10.0, 100)
	_assert_true(runtime.is_defeated(), "a rival crowd at zero is defeated")


func _test_rival_crowd_resolves_to_absolute_difference() -> void:
	var starting_crowd: int = 130
	var starting_rival: int = 80
	var runtime := RivalCrowdRuntime.new(starting_rival)
	var crowd_count: int = starting_crowd
	var ticks: int = 0
	while not runtime.is_defeated() and ticks < 10000:
		var loss: int = runtime.tick(0.1, crowd_count)
		crowd_count -= loss
		ticks += 1
	_assert_true(runtime.is_defeated(), "the rival crowd is eventually defeated")
	_assert_eq(
		crowd_count,
		starting_crowd - starting_rival,
		"the surviving crowd matches the 1-for-1 result of an instant subtraction"
	)


func _test_rival_crowd_tick_does_nothing_once_defeated() -> void:
	var runtime := RivalCrowdRuntime.new(5)
	runtime.tick(10.0, 100)
	_assert_true(runtime.is_defeated(), "setup: rival is defeated")
	var loss: int = runtime.tick(10.0, 100)
	_assert_eq(loss, 0, "ticking a defeated rival crowd returns zero loss")


func _test_build_multimesh_transforms_matches_crowd_layout_count() -> void:
	var transforms: Array[Transform3D] = RunRules.build_multimesh_transforms(40)
	_assert_eq(
		transforms.size(),
		RunRules.crowd_layout(40).size(),
		"multimesh transforms match crowd_layout's instance count"
	)


func _test_apply_shot_damage_reduces_and_clamps_at_zero() -> void:
	var runtime := RivalCrowdRuntime.new(10)
	var applied: int = runtime.apply_shot_damage(1.0, 15)
	_assert_eq(applied, 10, "shot damage applied is clamped to what's left")
	_assert_eq(runtime.rival_count, 0, "rival count clamps at zero, never negative")


func _test_apply_shot_damage_is_cooldown_gated() -> void:
	var runtime := RivalCrowdRuntime.new(100)
	var first: int = runtime.apply_shot_damage(0.0, 10)
	var second: int = runtime.apply_shot_damage(0.01, 10)
	_assert_eq(first, 10, "the first shot applies immediately")
	_assert_eq(second, 0, "a second shot before FIRE_INTERVAL has passed applies nothing")


func _test_apply_shot_damage_then_tick_carries_count_across_phases() -> void:
	var runtime := RivalCrowdRuntime.new(100)
	runtime.apply_shot_damage(0.0, 40)
	_assert_eq(runtime.rival_count, 60, "shooting reduces the count before contact")
	var crowd_count: int = 150
	var ticks: int = 0
	while not runtime.is_defeated() and ticks < 10000:
		var loss: int = runtime.tick(0.1, crowd_count)
		crowd_count -= loss
		ticks += 1
	_assert_true(runtime.is_defeated(), "the remainder is fully resolved by contact")
	_assert_eq(
		crowd_count,
		150 - 60,
		"the crowd survives the contact phase using whatever the shooting phase left behind"
	)


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
