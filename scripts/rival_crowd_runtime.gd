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
#
# bullets: apply_shot_damage() applies its damage instantly (unlike
# enemy_wave_runtime.gd, where a bullet travels before resolving a hit) -
# these entries are purely a visual record of "a shot was just fired from
# here", consumed by advance_bullets()/rival_crowd_visual.gd so the player
# sees something leave the crowd, not just the horde's count silently
# dropping. tick() never touches this array; a plain rival crowd's bullets
# stays empty forever.

const RivalCrowdRules := preload("res://scripts/rival_crowd_rules.gd")
const CombatRules := preload("res://scripts/combat_rules.gd")
const RunRules := preload("res://scripts/run_rules.gd")

var rival_count: int
var bullets: Array[Dictionary] = []

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


func apply_shot_damage(delta: float, shots: int, crowd_distance: float, crowd_count: int) -> int:
	if is_defeated():
		return 0
	_fire_cooldown -= delta
	if _fire_cooldown > 0.0:
		return 0
	_fire_cooldown = CombatRules.FIRE_INTERVAL
	var applied: int = mini(shots, rival_count)
	rival_count -= applied
	# Only as many bullets as damage actually applied - a volley bigger than
	# what's left to kill would otherwise show bullets flying at nothing.
	# Each starts from a random point along the crowd's actual front edge -
	# many individual men firing, not a single point fanning out evenly.
	var half_width: float = RunRules.crowd_front_edge_half_width(crowd_count)
	for i in applied:
		bullets.append(
			{
				"distance": crowd_distance,
				"offset": randf_range(-half_width, half_width),
				"height": (
					CombatRules.SHOT_HEIGHT
					+ randf_range(-CombatRules.SHOT_HEIGHT_JITTER, CombatRules.SHOT_HEIGHT_JITTER)
				),
			}
		)
	return applied


func advance_bullets(delta: float, target_distance: float) -> void:
	var remaining: Array[Dictionary] = []
	for bullet in bullets:
		bullet["distance"] += CombatRules.BULLET_SPEED * delta
		if bullet["distance"] < target_distance:
			remaining.append(bullet)
	bullets = remaining
