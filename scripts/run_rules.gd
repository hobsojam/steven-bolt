extends RefCounted

const LANE_COUNT := 5
const LANE_SPACING := 1.6
const RUN_SPEED := 6.0
const LANE_SWITCH_SPEED := 10.0
const SWIPE_THRESHOLD_PX := 40.0


static func lane_x(lane_index: int) -> float:
	return (lane_index - (LANE_COUNT - 1) / 2.0) * LANE_SPACING
