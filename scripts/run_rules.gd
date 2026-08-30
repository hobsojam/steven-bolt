extends RefCounted

const LANE_COUNT := 5
const LANE_SPACING := 1.6
const RUN_SPEED := 6.0
const MAX_RUN_SPEED := 11.0
const SPEED_RAMP_PER_SECOND := 0.15
const SWIPE_THRESHOLD_PX := 40.0
const START_CROWD_COUNT := 1
const MAX_RENDERED_UNITS := 150
const CROWD_UNIT_SPACING := 0.6
const CROWD_MAX_WIDTH := 6.0
const CROWD_MAX_DEPTH := 3.0
const CROWD_SCALE_PER_DOUBLING := 0.85

# Enemy hordes render as their own dense mass rather than reusing the
# player crowd's compact, camera-tuned layout: they sit ahead of the
# player, so filling the track width and receding toward the horizon is
# the point. Full-size units (no count-based shrink), a higher on-screen
# cap than the player crowd, and rows that extend away from the player.
const MAX_ENEMY_MASS_UNITS := 300
const ENEMY_MASS_WIDTH := 7.0
const ENEMY_MASS_UNIT_SPACING := 0.62


static func lane_x(lane_index: int) -> float:
	return (lane_index - (LANE_COUNT - 1) / 2.0) * LANE_SPACING


static func clamped_lane(current_lane: int, lane_delta: int) -> int:
	return clampi(current_lane + lane_delta, 0, LANE_COUNT - 1)


static func lane_steps_from_drag(drag_delta_x: float) -> int:
	return int(drag_delta_x / SWIPE_THRESHOLD_PX)


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


static func build_multimesh_transforms(count: int) -> Array[Transform3D]:
	var positions: Array[Vector3] = crowd_layout(count)
	var scale: float = crowd_unit_scale(count)
	var basis := Basis().scaled(Vector3.ONE * scale)
	var transforms: Array[Transform3D] = []
	for pos in positions:
		transforms.append(Transform3D(basis, pos))
	return transforms


static func crowd_front_edge_half_width(count: int) -> float:
	# Reuses crowd_layout() itself (rather than re-deriving the column/
	# spacing math) so this always matches the actual rendered crowd's
	# width exactly, including its width/depth caps - used to scatter shot
	# origins across "the crowd" instead of a single point.
	var half_width: float = 0.0
	for pos in crowd_layout(count):
		if pos.z == 0.0:
			half_width = maxf(half_width, absf(pos.x))
	return half_width


static func enemy_mass_layout(count: int) -> Array[Vector3]:
	var rendered: int = clampi(count, 0, MAX_ENEMY_MASS_UNITS)
	var positions: Array[Vector3] = []
	if rendered <= 0:
		return positions
	var columns: int = mini(maxi(1, int(ENEMY_MASS_WIDTH / ENEMY_MASS_UNIT_SPACING)), rendered)
	for i in rendered:
		var col: int = i % columns
		var row: int = i / columns
		var x: float = (col - (columns - 1) / 2.0) * ENEMY_MASS_UNIT_SPACING
		# Rows recede away from the player toward the horizon, so the front
		# rank sits at local z = 0 - where the crowd's fire lands.
		var z: float = -row * ENEMY_MASS_UNIT_SPACING
		# Deterministic per-index jitter (same result every call, so this
		# stays headlessly testable) breaks up the grid into an organic mass.
		# Amplitude stays under half a spacing so units never swap cells.
		x += (_index_hash(i, 127.1) - 0.5) * ENEMY_MASS_UNIT_SPACING * 0.55
		z += (_index_hash(i, 311.7) - 0.5) * ENEMY_MASS_UNIT_SPACING * 0.55
		positions.append(Vector3(x, 0.0, z))
	return positions


static func build_enemy_mass_transforms(count: int) -> Array[Transform3D]:
	var transforms: Array[Transform3D] = []
	for pos in enemy_mass_layout(count):
		transforms.append(Transform3D(Basis.IDENTITY, pos))
	return transforms


static func enemy_mass_survivor_transforms(
	full_count: int, alive_count: int
) -> Array[Transform3D]:
	# The mass is laid out once at its full size (front rank first). As it
	# loses units they die from the front rank - the one facing the crowd's
	# fire - inward, so the survivors are the *tail* of that layout and keep
	# their original positions. Rendering the tail (rather than truncating
	# the head) is what makes fire visibly carve the mass back instead of
	# thinning it from the hidden far side.
	var all: Array[Transform3D] = build_enemy_mass_transforms(full_count)
	var shown: int = clampi(alive_count, 0, all.size())
	return all.slice(all.size() - shown)


static func _index_hash(index: int, salt: float) -> float:
	# Cheap deterministic hash -> [0, 1). Not statistically great, but stable
	# and dependency-free, which is all the mass jitter needs.
	return fmod(absf(sin(float(index) * salt) * 43758.5453), 1.0)
