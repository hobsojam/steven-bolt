extends SceneTree

const RunRules := preload("res://scripts/run_rules.gd")
const ChaseCamera := preload("res://scripts/chase_camera.gd")
const LevelOneDefinition := preload("res://scripts/level_one_definition.gd")
const CombatRules := preload("res://scripts/combat_rules.gd")
const EnemyWaveRuntime := preload("res://scripts/enemy_wave_runtime.gd")
const RivalCrowdRules := preload("res://scripts/rival_crowd_rules.gd")
const RivalCrowdRuntime := preload("res://scripts/rival_crowd_runtime.gd")
const EnemyWaveEncounter := preload("res://scripts/enemy_wave_encounter.gd")
const RivalCrowdEncounter := preload("res://scripts/rival_crowd_encounter.gd")
const HordeEncounter := preload("res://scripts/horde_encounter.gd")
const MainScene := preload("res://scenes/main.tscn")
const EnvironmentZones := preload("res://scripts/environment_zones.gd")

var _failures: int = 0


func _initialize() -> void:
	_test_apply_gate_addition()
	_test_apply_gate_subtraction()
	_test_apply_gate_underflow_clamps_to_zero()
	_test_apply_gate_exact_zero()
	_test_apply_gate_stacking()
	_test_lane_x_symmetry()
	_test_clamped_lane_moves_multiple_steps()
	_test_clamped_lane_stops_at_boundaries()
	_test_lane_steps_from_drag_respects_threshold()
	_test_lane_steps_from_drag_preserves_direction_and_magnitude()
	_test_crowd_input_keeps_lane_and_visual_root_in_sync()
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
	_test_entries_contain_a_horde_before_finish()
	_test_environment_zones_are_contiguous_and_cover_the_level()
	_test_zone_for_distance_clamps_before_the_first_zone()
	_test_zone_for_distance_resolves_boundary_to_the_zone_that_starts_there()
	_test_zone_for_distance_clamps_past_the_last_zone()
	_test_prop_positions_for_zone_covers_the_full_span()
	_test_prop_positions_for_zone_alternates_sides()
	_test_shots_per_volley_scales_with_crowd_count()
	_test_shots_per_volley_caps_at_max()
	_test_crowd_front_edge_half_width_grows_with_crowd_count()
	_test_nearest_enemy_index_in_lane_picks_closest()
	_test_apply_hit_kills_at_zero_hp()
	_test_try_fire_and_resolve_hits_kills_enemy()
	_test_resolve_hits_drops_bullets_with_no_live_target()
	_test_resolve_breaches_costs_only_alive_crossed_enemies()
	_test_rival_crowd_many_small_ticks_accumulate_nonzero_loss()
	_test_rival_crowd_tick_never_exceeds_smaller_count()
	_test_rival_crowd_is_defeated_at_zero()
	_test_rival_crowd_resolves_to_absolute_difference()
	_test_rival_crowd_tick_does_nothing_once_defeated()
	_test_build_multimesh_transforms_matches_crowd_layout_count()
	_test_enemy_mass_layout_empty_for_zero()
	_test_enemy_mass_layout_caps_at_max()
	_test_enemy_mass_layout_spans_full_track_width()
	_test_enemy_mass_layout_recedes_toward_horizon()
	_test_enemy_mass_layout_is_deterministic()
	_test_build_enemy_mass_transforms_matches_layout_count()
	_test_apply_shot_damage_reduces_and_clamps_at_zero()
	_test_apply_shot_damage_is_cooldown_gated()
	_test_apply_shot_damage_spawns_one_bullet_per_shot()
	_test_apply_shot_damage_spawns_only_as_many_bullets_as_damage_applied()
	_test_advance_bullets_moves_and_despawns_at_target()
	_test_apply_shot_damage_then_tick_carries_count_across_phases()
	_test_enemy_wave_encounter_shoots_kills_and_completes()
	_test_enemy_wave_encounter_charges_breach_for_crossed_enemy()
	_test_horde_encounter_shoots_before_contact_then_completes()
	_test_horde_encounter_contact_phase_charges_breach()
	_test_rival_crowd_encounter_engages_only_after_its_distance()

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


func _test_clamped_lane_moves_multiple_steps() -> void:
	_assert_eq(RunRules.clamped_lane(1, 2), 3, "rapid lane input can move multiple steps")
	_assert_eq(RunRules.clamped_lane(3, -2), 1, "multi-step movement works in both directions")


func _test_clamped_lane_stops_at_boundaries() -> void:
	_assert_eq(RunRules.clamped_lane(0, -1), 0, "left input clamps at the first lane")
	_assert_eq(
		RunRules.clamped_lane(RunRules.LANE_COUNT - 1, 3),
		RunRules.LANE_COUNT - 1,
		"right input clamps at the last lane"
	)


func _test_lane_steps_from_drag_respects_threshold() -> void:
	_assert_eq(RunRules.lane_steps_from_drag(39.9), 0, "a short drag stays in its lane")
	_assert_eq(RunRules.lane_steps_from_drag(40.0), 1, "the threshold advances one lane")
	_assert_eq(RunRules.lane_steps_from_drag(-40.0), -1, "the negative threshold moves left")


func _test_lane_steps_from_drag_preserves_direction_and_magnitude() -> void:
	_assert_eq(RunRules.lane_steps_from_drag(125.0), 3, "a large drag advances multiple lanes")
	_assert_eq(RunRules.lane_steps_from_drag(-95.0), -2, "large left drags retain direction")


func _test_crowd_input_keeps_lane_and_visual_root_in_sync() -> void:
	var main := MainScene.instantiate()
	root.add_child(main)
	var crowd = main.get_node("CrowdController")
	# This suite runs from SceneTree._initialize(), before @onready assignments
	# fire on an instantiated scene. Bind the child that _ready would resolve.
	crowd._crowd_visual = crowd.get_node("CrowdVisual")
	var keyboard := InputEventKey.new()
	keyboard.keycode = KEY_D
	keyboard.pressed = true
	crowd._unhandled_input(keyboard)
	_assert_eq(crowd.current_lane, 3, "keyboard input advances one lane")
	_assert_true(
		absf(crowd.position.x - RunRules.lane_x(crowd.current_lane)) < 0.001,
		"keyboard input keeps the visible root on its resolved lane"
	)
	var mouse_down := InputEventMouseButton.new()
	mouse_down.button_index = MOUSE_BUTTON_LEFT
	mouse_down.pressed = true
	mouse_down.position = Vector2.ZERO
	crowd._unhandled_input(mouse_down)
	var mouse_drag := InputEventMouseMotion.new()
	mouse_drag.position = Vector2(85.0, 0.0)
	crowd._unhandled_input(mouse_drag)
	_assert_eq(crowd.current_lane, 4, "mouse drag clamps rapid movement at the track edge")
	_assert_true(
		absf(crowd.position.x - RunRules.lane_x(crowd.current_lane)) < 0.001,
		"mouse drag keeps the visible root on its resolved lane"
	)
	var touch_down := InputEventScreenTouch.new()
	touch_down.index = 0
	touch_down.pressed = true
	touch_down.position = Vector2(100.0, 0.0)
	crowd._unhandled_input(touch_down)
	var touch_drag := InputEventScreenDrag.new()
	touch_drag.index = 0
	touch_drag.position = Vector2(15.0, 0.0)
	crowd._unhandled_input(touch_drag)
	_assert_eq(crowd.current_lane, 2, "touch drag consumes multiple lane thresholds")
	_assert_true(
		absf(crowd.position.x - RunRules.lane_x(crowd.current_lane)) < 0.001,
		"touch drag keeps the visible root on its resolved lane"
	)
	main.free()


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


func _test_entries_contain_a_horde_before_finish() -> void:
	var horde: Dictionary = {}
	for entry in LevelOneDefinition.entries():
		if entry["kind"] == "horde":
			horde = entry
			break
	_assert_true(not horde.is_empty(), "the level has a horde entry")
	_assert_true(horde["count"] > 0, "the horde starts with a positive count")
	_assert_true(
		LevelOneDefinition.length() - horde["distance"] >= 10.0,
		"the horde has at least some runway before the finish line"
	)


func _test_environment_zones_are_contiguous_and_cover_the_level() -> void:
	var zones: Array[Dictionary] = EnvironmentZones.zones()
	_assert_eq(zones[0]["start_distance"], 0.0, "the first zone starts at the beginning")
	_assert_true(
		zones[zones.size() - 1]["end_distance"] >= LevelOneDefinition.length(),
		"the last zone reaches at least the end of the level"
	)
	for i in range(zones.size() - 1):
		_assert_eq(
			zones[i]["end_distance"],
			zones[i + 1]["start_distance"],
			"consecutive zones share a boundary with no gap or overlap"
		)


func _test_zone_for_distance_clamps_before_the_first_zone() -> void:
	var zones: Array[Dictionary] = EnvironmentZones.zones()
	_assert_eq(
		EnvironmentZones.zone_for_distance(-5.0, zones),
		zones[0],
		"a distance before the level start clamps to the first zone"
	)


func _test_zone_for_distance_resolves_boundary_to_the_zone_that_starts_there() -> void:
	var zones: Array[Dictionary] = EnvironmentZones.zones()
	var boundary: float = zones[0]["end_distance"]
	_assert_eq(
		EnvironmentZones.zone_for_distance(boundary, zones),
		zones[1],
		"a distance exactly on a boundary resolves to the zone starting there"
	)


func _test_zone_for_distance_clamps_past_the_last_zone() -> void:
	var zones: Array[Dictionary] = EnvironmentZones.zones()
	_assert_eq(
		EnvironmentZones.zone_for_distance(zones[zones.size() - 1]["end_distance"] + 100.0, zones),
		zones[zones.size() - 1],
		"a distance past the level end clamps to the last zone"
	)


func _test_prop_positions_for_zone_covers_the_full_span() -> void:
	var zone: Dictionary = {"start_distance": 0.0, "end_distance": 40.0, "prop_spacing": 8.0}
	var positions: Array[Vector3] = EnvironmentZones.prop_positions_for_zone(zone, 5.0)
	_assert_eq(positions.size(), 5, "a 40-unit zone at 8-unit spacing places 5 props")
	for pos in positions:
		_assert_true(
			pos.z <= 0.0 and pos.z > -zone["end_distance"],
			"every prop position falls within the zone's distance range"
		)


func _test_prop_positions_for_zone_alternates_sides() -> void:
	var zone: Dictionary = {"start_distance": 0.0, "end_distance": 40.0, "prop_spacing": 8.0}
	var positions: Array[Vector3] = EnvironmentZones.prop_positions_for_zone(zone, 5.0)
	_assert_true(positions[0].x > 0.0, "the first prop is placed on the right side")
	_assert_true(positions[1].x < 0.0, "the second prop alternates to the left side")


func _test_shots_per_volley_scales_with_crowd_count() -> void:
	_assert_eq(CombatRules.shots_per_volley(0), 1, "shot count has a floor of 1 with no crowd")
	_assert_true(
		CombatRules.shots_per_volley(200) > CombatRules.shots_per_volley(20),
		"shot count increases as crowd count grows"
	)


func _test_shots_per_volley_caps_at_max() -> void:
	_assert_eq(
		CombatRules.shots_per_volley(1000000),
		CombatRules.MAX_SHOTS_PER_VOLLEY,
		"shot count per volley is capped for sanity at extreme crowd sizes"
	)


func _test_crowd_front_edge_half_width_grows_with_crowd_count() -> void:
	_assert_eq(
		RunRules.crowd_front_edge_half_width(0), 0.0, "an empty crowd has no front edge width"
	)
	_assert_true(
		RunRules.crowd_front_edge_half_width(50) > RunRules.crowd_front_edge_half_width(2),
		"a bigger crowd has a wider front edge to scatter shot origins across"
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
	runtime.try_fire(0, 0.0, 1, 50, 1.0)
	_assert_eq(runtime.bullets.size(), 1, "a target in range fires a bullet")
	runtime.advance_bullets(1.0)
	var killed: Array[int] = runtime.resolve_hits()
	_assert_eq(killed, [0], "a bullet that reaches the enemy's distance kills it")
	_assert_true(runtime.is_cleared(), "the wave is cleared once its only enemy is killed")


func _test_resolve_hits_drops_bullets_with_no_live_target() -> void:
	var runtime := EnemyWaveRuntime.new([{"lane": 0, "distance": 10.0, "hp": 1}])
	runtime.try_fire(0, 0.0, 3, 50, 1.0)
	_assert_eq(runtime.bullets.size(), 3, "a volley of 3 shots fires 3 bullets")
	_assert_true(
		runtime.bullets[0]["offset"] != runtime.bullets[2]["offset"],
		"bullets in a volley are laterally spread apart"
	)
	runtime.advance_bullets(1.0)
	var killed: Array[int] = runtime.resolve_hits()
	_assert_eq(killed, [0], "the enemy dies exactly once despite the overkill volley")
	_assert_eq(
		runtime.bullets.size(), 0, "leftover bullets with no live target are dropped, not kept forever"
	)


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


func _test_enemy_mass_layout_empty_for_zero() -> void:
	_assert_eq(RunRules.enemy_mass_layout(0).size(), 0, "a zero-count horde renders no instances")


func _test_enemy_mass_layout_caps_at_max() -> void:
	_assert_eq(
		RunRules.enemy_mass_layout(100000).size(),
		RunRules.MAX_ENEMY_MASS_UNITS,
		"the enemy mass instance count caps at MAX_ENEMY_MASS_UNITS"
	)


func _test_enemy_mass_layout_spans_full_track_width() -> void:
	var max_abs_x: float = 0.0
	for pos in RunRules.enemy_mass_layout(RunRules.MAX_ENEMY_MASS_UNITS):
		max_abs_x = maxf(max_abs_x, absf(pos.x))
	_assert_true(
		max_abs_x > RunRules.ENEMY_MASS_WIDTH / 2.0 - RunRules.ENEMY_MASS_UNIT_SPACING,
		"a full horde spreads its outer units out to near the track edge"
	)
	_assert_true(
		max_abs_x <= RunRules.ENEMY_MASS_WIDTH / 2.0 + RunRules.ENEMY_MASS_UNIT_SPACING,
		"jitter never throws a unit meaningfully past the intended mass width"
	)


func _test_enemy_mass_layout_recedes_toward_horizon() -> void:
	var min_z: float = 0.0
	for pos in RunRules.enemy_mass_layout(RunRules.MAX_ENEMY_MASS_UNITS):
		min_z = minf(min_z, pos.z)
	_assert_true(
		min_z < -RunRules.CROWD_MAX_DEPTH,
		"the enemy mass is far deeper than the compact player-crowd layout - a wall, not a blob"
	)


func _test_enemy_mass_layout_is_deterministic() -> void:
	var count: int = 120
	var first: Array[Vector3] = RunRules.enemy_mass_layout(count)
	var second: Array[Vector3] = RunRules.enemy_mass_layout(count)
	_assert_true(
		first == second,
		"the layout (including its jitter) is identical across calls, so it stays testable"
	)


func _test_build_enemy_mass_transforms_matches_layout_count() -> void:
	_assert_eq(
		RunRules.build_enemy_mass_transforms(180).size(),
		RunRules.enemy_mass_layout(180).size(),
		"enemy mass transforms match enemy_mass_layout's instance count"
	)


func _test_apply_shot_damage_reduces_and_clamps_at_zero() -> void:
	var runtime := RivalCrowdRuntime.new(10)
	var applied: int = runtime.apply_shot_damage(1.0, 15, 0.0, 50)
	_assert_eq(applied, 10, "shot damage applied is clamped to what's left")
	_assert_eq(runtime.rival_count, 0, "rival count clamps at zero, never negative")


func _test_apply_shot_damage_is_cooldown_gated() -> void:
	var runtime := RivalCrowdRuntime.new(100)
	var first: int = runtime.apply_shot_damage(0.0, 10, 0.0, 50)
	var second: int = runtime.apply_shot_damage(0.01, 10, 0.0, 50)
	_assert_eq(first, 10, "the first shot applies immediately")
	_assert_eq(second, 0, "a second shot before FIRE_INTERVAL has passed applies nothing")


func _test_apply_shot_damage_spawns_one_bullet_per_shot() -> void:
	var runtime := RivalCrowdRuntime.new(100)
	runtime.apply_shot_damage(0.0, 3, 42.0, 50)
	_assert_eq(runtime.bullets.size(), 3, "a fired volley spawns one bullet per shot")
	for bullet in runtime.bullets:
		_assert_eq(
			bullet["distance"], 42.0, "each bullet starts at the crowd's current distance"
		)
	runtime.apply_shot_damage(0.01, 3, 43.0, 50)
	_assert_eq(runtime.bullets.size(), 3, "a shot still on cooldown does not spawn more bullets")


func _test_apply_shot_damage_spawns_only_as_many_bullets_as_damage_applied() -> void:
	var runtime := RivalCrowdRuntime.new(4)
	runtime.apply_shot_damage(0.0, 10, 0.0, 50)
	_assert_eq(
		runtime.bullets.size(),
		4,
		"bullet count is clamped to the damage actually applied, not the full volley"
	)


func _test_advance_bullets_moves_and_despawns_at_target() -> void:
	var runtime := RivalCrowdRuntime.new(100)
	runtime.apply_shot_damage(0.0, 1, 0.0, 50)
	runtime.advance_bullets(1.0, 1000.0)
	_assert_eq(
		runtime.bullets[0]["distance"],
		CombatRules.BULLET_SPEED,
		"the bullet advances by BULLET_SPEED * delta"
	)
	runtime.advance_bullets(1000.0, 1000.0)
	_assert_eq(runtime.bullets.size(), 0, "the bullet despawns once it reaches the target distance")


func _test_apply_shot_damage_then_tick_carries_count_across_phases() -> void:
	var runtime := RivalCrowdRuntime.new(100)
	runtime.apply_shot_damage(0.0, 40, 0.0, 50)
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


func _test_enemy_wave_encounter_shoots_kills_and_completes() -> void:
	var encounter := EnemyWaveEncounter.new({"enemies": [{"lane": 0, "distance": 10.0, "hp": 1}]})
	_assert_true(not encounter.is_complete(), "a fresh wave with a live enemy is not complete")
	var ctx := {"crowd_count": 50, "current_lane": 0, "distance_traveled": 0.0, "crowd_z": 0.0}
	var result: Dictionary = encounter.update(1.0, ctx)
	_assert_true(
		_feedback_amount(result, &"shot") >= 1,
		"the wave encounter fires a volley and reports it as a shot feedback event"
	)
	_assert_eq(
		_feedback_amount(result, &"hit"), 1, "the volley kills the lone in-lane enemy in one update"
	)
	_assert_eq(result["breach_cost"], 0, "a shot-down enemy is never charged as a breach")
	_assert_true(encounter.is_complete(), "the wave encounter is complete once every enemy is dead")
	encounter.cleanup()
	encounter.cleanup()


func _test_enemy_wave_encounter_charges_breach_for_crossed_enemy() -> void:
	var encounter := EnemyWaveEncounter.new({"enemies": [{"lane": 3, "distance": 5.0, "hp": 5}]})
	# Crowd sits in lane 0, so nothing shoots the lane-3 enemy before its
	# distance is crossed at distance_traveled 6.
	var ctx := {"crowd_count": 20, "current_lane": 0, "distance_traveled": 6.0, "crowd_z": -6.0}
	var result: Dictionary = encounter.update(0.1, ctx)
	_assert_eq(
		result["breach_cost"],
		CombatRules.ENEMY_BREACH_COST,
		"an un-killed enemy whose distance is crossed charges exactly one breach cost"
	)
	_assert_true(
		encounter.is_complete(), "the wave encounter clears once its only enemy has breached"
	)


func _test_horde_encounter_shoots_before_contact_then_completes() -> void:
	var encounter := HordeEncounter.new({"count": 6, "distance": 100.0})
	var far: Dictionary = encounter.update(
		1.0, {"crowd_count": 50, "current_lane": 2, "distance_traveled": 60.0, "crowd_z": -60.0}
	)
	_assert_true(
		far["feedback"].is_empty() and far["breach_cost"] == 0,
		"a horde further than its shoot range away is inert"
	)
	_assert_true(not encounter.is_complete(), "an untouched horde is not complete")
	var ctx := {"crowd_count": 50, "current_lane": 2, "distance_traveled": 85.0, "crowd_z": -85.0}
	var completed := false
	for _i in 20:
		var result: Dictionary = encounter.update(1.0, ctx)
		_assert_eq(result["breach_cost"], 0, "the horde shooting phase never charges a breach")
		if encounter.is_complete():
			completed = true
			break
	_assert_true(completed, "a small horde is shot down before contact and completes")


func _test_horde_encounter_contact_phase_charges_breach() -> void:
	var encounter := HordeEncounter.new({"count": 1000, "distance": 100.0})
	# Contact reached (distance_traveled >= engage distance) with the horde
	# far too large to have been shot down first.
	var ctx := {"crowd_count": 200, "current_lane": 2, "distance_traveled": 100.0, "crowd_z": -100.0}
	var total_breach := 0
	for _i in 5:
		total_breach += encounter.update(0.1, ctx)["breach_cost"]
	_assert_true(total_breach > 0, "a horde that survives to contact bleeds the crowd by attrition")


func _test_rival_crowd_encounter_engages_only_after_its_distance() -> void:
	var encounter := RivalCrowdEncounter.new({"count": 30, "distance": 50.0})
	var before: Dictionary = encounter.update(
		1.0, {"crowd_count": 100, "current_lane": 2, "distance_traveled": 20.0, "crowd_z": -20.0}
	)
	_assert_true(
		before["feedback"].is_empty() and before["breach_cost"] == 0,
		"a rival crowd is inert before the crowd reaches its engage distance"
	)
	_assert_true(not encounter.is_complete(), "an un-engaged rival crowd is not complete")
	var ctx := {"crowd_count": 100, "current_lane": 2, "distance_traveled": 55.0, "crowd_z": -55.0}
	var total_breach := 0
	var completed := false
	for _i in 200:
		total_breach += encounter.update(0.1, ctx)["breach_cost"]
		if encounter.is_complete():
			completed = true
			break
	_assert_true(completed, "the rival crowd resolves by attrition once engaged")
	_assert_eq(
		total_breach, 30, "the crowd's total losses equal the rival crowd's starting count (1-for-1)"
	)


func _feedback_amount(result: Dictionary, kind: StringName) -> int:
	for event in result["feedback"]:
		if event[0] == kind:
			return event[1]
	return -1


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
