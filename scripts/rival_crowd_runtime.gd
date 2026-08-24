extends RefCounted

# Pure tick-resolution logic, deliberately independent of the scene tree
# (same "keep pure math testable" principle as enemy_wave_runtime.gd).
#
# Dual-purpose: a plain rival crowd only ever calls tick() (mutual contact
# attrition, engaged the moment the crowd reaches it). A horde also calls
# apply_shot_damage() while still approaching - a one-sided reduction from
# being shot, same fire-cooldown shape as enemy_wave_runtime.gd's try_fire -
# before falling through to the exact same tick() for whatever survives the
# shooting phase. Both call sites and both level-entry kinds share this one
# class; there's no behavioral difference for a "pure" rival crowd that
# never calls apply_shot_damage.
#
# tick(): both sides lose the same amount each tick, clamped to whichever
# count is smaller - so gradual resolution converges to the exact same
# result an instant 1-for-1 subtraction would (survivor_count = |a - b|),
# just spread out over time for pacing. Both tick() and apply_shot_damage()
# accumulate loss as a float and only subtract whole units once it crosses
# 1, or a low per-second/per-shot rate at a high framerate would truncate
# to a 0 loss every single frame forever.

const RivalCrowdRules := preload("res://scripts/rival_crowd_rules.gd")
const CombatRules := preload("res://scripts/combat_rules.gd")

var rival_count: int

var _loss_accumulator: float = 0.0
var _fire_cooldown: float = 0.0


func _init(starting_count: int) -> void:
	rival_count = starting_count


func is_defeated() -> bool:
	return rival_count <= 0


func tick(delta: float, crowd_count: int) -> int:
	if is_defeated() or crowd_count <= 0:
		return 0
	_loss_accumulator += RivalCrowdRules.LOSS_RATE_PER_SECOND * delta
	var loss: int = mini(int(_loss_accumulator), mini(crowd_count, rival_count))
	_loss_accumulator -= loss
	rival_count -= loss
	return loss


func apply_shot_damage(delta: float, damage: int) -> int:
	if is_defeated():
		return 0
	_fire_cooldown -= delta
	if _fire_cooldown > 0.0:
		return 0
	_fire_cooldown = CombatRules.FIRE_INTERVAL
	var applied: int = mini(damage, rival_count)
	rival_count -= applied
	return applied
