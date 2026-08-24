extends RefCounted

# Pure tick-resolution logic, deliberately independent of the scene tree
# (same "keep pure math testable" principle as enemy_wave_runtime.gd).
#
# Both sides lose the same amount each tick, clamped to whichever count is
# smaller - so gradual resolution converges to the exact same result an
# instant 1-for-1 subtraction would (survivor_count = |a - b|), just spread
# out over time for pacing. The loss is accumulated as a float and only
# subtracted in whole units once it crosses 1, or a low per-second rate at
# a high framerate would truncate to a 0 loss every single frame forever.

const RivalCrowdRules := preload("res://scripts/rival_crowd_rules.gd")

var rival_count: int

var _loss_accumulator: float = 0.0


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
