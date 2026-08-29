extends "res://scripts/encounter.gd"

# An enemy wave: a spread of stationary enemies the crowd auto-fires on
# as it approaches. Un-killed enemies charge a breach cost per head when
# their distance is crossed, regardless of the crowd's own lane. All the
# hit / kill / breach math lives in enemy_wave_runtime.gd; this class is
# the lifecycle wrapper.

const CombatRules := preload("res://scripts/combat_rules.gd")
const EnemyWaveRuntimeScript := preload("res://scripts/enemy_wave_runtime.gd")
const EnemyWaveVisualScript := preload("res://scripts/enemy_wave_visual.gd")

var _runtime = null


func _init(entry: Dictionary) -> void:
	super(entry)
	_runtime = EnemyWaveRuntimeScript.new(entry["enemies"])


func spawn(parent: Node3D) -> void:
	_visual = EnemyWaveVisualScript.new(_runtime)
	parent.add_child(_visual)


func update(delta: float, ctx: Dictionary) -> Dictionary:
	var feedback: Array = []
	var shots: int = CombatRules.shots_per_volley(ctx["crowd_count"])
	var bullets_before: int = _runtime.bullets.size()
	_runtime.try_fire(
		ctx["current_lane"], ctx["distance_traveled"], shots, ctx["crowd_count"], delta
	)
	if _runtime.bullets.size() > bullets_before:
		feedback.append([&"shot", _runtime.bullets.size() - bullets_before])
	_runtime.advance_bullets(delta)
	var killed: Array[int] = _runtime.resolve_hits()
	if not killed.is_empty():
		feedback.append([&"hit", killed.size()])
	var breach_cost: int = _runtime.resolve_breaches(ctx["distance_traveled"])
	return {"feedback": feedback, "breach_cost": breach_cost}


func is_complete() -> bool:
	return _runtime.is_cleared()
