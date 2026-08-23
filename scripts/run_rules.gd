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
const CROWD_MAX_WIDTH := 6.0


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


static func crowd_layout(crowd_count: int) -> Array[Vector3]:
	var rendered: int = mini(crowd_count, MAX_RENDERED_UNITS)
	var positions: Array[Vector3] = []
	if rendered <= 0:
		return positions
	var desired_width: float = sqrt(float(rendered)) * CROWD_UNIT_SPACING
	var width: float = minf(desired_width, CROWD_MAX_WIDTH)
	var columns: int = mini(maxi(1, int(width / CROWD_UNIT_SPACING)), rendered)
	for i in rendered:
		var col: int = i % columns
		var row: int = i / columns
		var x: float = (col - (columns - 1) / 2.0) * CROWD_UNIT_SPACING
		var z: float = row * CROWD_UNIT_SPACING
		positions.append(Vector3(x, 0.0, z))
	return positions
