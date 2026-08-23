extends RefCounted

const FIRE_INTERVAL := 0.35
const BASE_SHOT_DAMAGE := 1
const CROWD_DAMAGE_DIVISOR := 20
const ENEMY_BREACH_COST := 10
const BULLET_SPEED := 30.0


static func shot_damage(crowd_count: int) -> int:
	return BASE_SHOT_DAMAGE + int(crowd_count / CROWD_DAMAGE_DIVISOR)
