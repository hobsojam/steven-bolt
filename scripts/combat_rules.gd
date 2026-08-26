extends RefCounted

const FIRE_INTERVAL := 0.35
const MIN_SHOTS_PER_VOLLEY := 1
const CROWD_SHOTS_DIVISOR := 20
const MAX_SHOTS_PER_VOLLEY := 30
const PER_SHOT_DAMAGE := 1
const SHOT_LATERAL_SPACING := 0.12
const ENEMY_BREACH_COST := 10
const BULLET_SPEED := 30.0


static func shots_per_volley(crowd_count: int) -> int:
	var shots: int = MIN_SHOTS_PER_VOLLEY + int(crowd_count / CROWD_SHOTS_DIVISOR)
	return mini(shots, MAX_SHOTS_PER_VOLLEY)


static func shot_offset(index: int, shot_count: int) -> float:
	return (index - (shot_count - 1) / 2.0) * SHOT_LATERAL_SPACING
