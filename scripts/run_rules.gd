extends RefCounted

const LANE_COUNT := 5
const LANE_SPACING := 1.6
const RUN_SPEED := 6.0
const MAX_RUN_SPEED := 11.0
const SPEED_RAMP_PER_SECOND := 0.15
const LANE_SWITCH_SPEED := 10.0
const SWIPE_THRESHOLD_PX := 40.0
const START_CROWD_COUNT := 20
const MAX_RENDERED_UNITS := 150
const CROWD_UNIT_SPACING := 0.6
const CROWD_UNIT_HALF_HEIGHT := 0.5
const CROWD_MAX_WIDTH := 6.0
const CROWD_MAX_DEPTH := 3.0
const CROWD_SCALE_PER_DOUBLING := 0.75


static func lane_x(lane_index: int) -> float:
	return (lane_index - (LANE_COUNT - 1) / 2.0) * LANE_SPACING


static func current_speed(elapsed_time: float) -> float:
	return minf(RUN_SPEED + SPEED_RAMP_PER_SECOND * elapsed_time, MAX_RUN_SPEED)


static func apply_gate(count: int, op: String, value: int) -> int:
	if op == "+":
		return count + value
	if op == "-":
		return maxi(count - value, 0)
	return count


static func can_pass_toll(count: int, threshold: int) -> bool:
	return count >= threshold


static func apply_toll(count: int, threshold: int) -> int:
	return count - threshold


static func crowd_unit_scale(crowd_count: int) -> float:
	if crowd_count <= 1:
		return 1.0
	var doublings: float = log(float(crowd_count)) / log(2.0)
	return pow(CROWD_SCALE_PER_DOUBLING, doublings)


static func crowd_layout(crowd_count: int) -> Array[Vector3]:
	var rendered: int = mini(crowd_count, MAX_RENDERED_UNITS)
	var positions: Array[Vector3] = []
	if rendered <= 0:
		return positions
	var spacing: float = CROWD_UNIT_SPACING * crowd_unit_scale(crowd_count)
	# Grow front-to-back first: start from a narrow, roughly-square footprint
	# (columns ~= sqrt(rendered)) rather than immediately spreading across
	# every lane. Only widen past that if the depth it would take to fit
	# everyone exceeds CROWD_MAX_DEPTH (kept well under the chase camera's
	# follow distance) - and even then, never past CROWD_MAX_WIDTH.
	var columns: int = mini(maxi(1, int(ceil(sqrt(float(rendered))))), rendered)
	var max_rows_for_depth: int = maxi(1, int(CROWD_MAX_DEPTH / spacing))
	if ceili(float(rendered) / columns) > max_rows_for_depth:
		columns = ceili(float(rendered) / max_rows_for_depth)
	var max_columns_for_width: int = maxi(1, int(CROWD_MAX_WIDTH / spacing))
	columns = clampi(columns, 1, mini(max_columns_for_width, rendered))
	for i in rendered:
		var col: int = i % columns
		var row: int = i / columns
		var x: float = (col - (columns - 1) / 2.0) * spacing
		var z: float = row * spacing
		positions.append(Vector3(x, 0.0, z))
	return positions
