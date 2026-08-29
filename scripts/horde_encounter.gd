extends "res://scripts/encounter.gd"

# A horde: a large enemy crowd that spans the whole track, so no lane
# dodges it. It has two phases, both resolved through
# rival_crowd_runtime.gd:
#
#   Shooting phase - from HORDE_SHOOT_RANGE ahead of the engage distance
#   up to contact, auto-fire chips the count down one-sidedly
#   (apply_shot_damage, same fire-cooldown shape as an enemy wave). A
#   clean shoot-down here costs the crowd nothing.
#
#   Contact phase - if any horde units survive to the engage distance,
#   the remainder resolves exactly like a rival crowd (tick), costing the
#   crowd whatever the horde had left.
#
# The shoot range exists because a horde would otherwise sit in firing
# range for the crowd's entire preceding run, trivializing even a large
# one.

const CombatRules := preload("res://scripts/combat_rules.gd")
const RivalCrowdRuntimeScript := preload("res://scripts/rival_crowd_runtime.gd")
const RivalCrowdVisualScript := preload("res://scripts/rival_crowd_visual.gd")
const EnemyModel := preload("res://assets/models/enemy.glb")

const HORDE_SHOOT_RANGE := 20.0

var _runtime = null
var _engage_distance: float = 0.0


func _init(entry: Dictionary) -> void:
	super(entry)
	_runtime = RivalCrowdRuntimeScript.new(entry["count"])
	_engage_distance = entry["distance"]


func spawn(parent: Node3D) -> void:
	# mass = true: render as a full-width crowd receding toward the horizon,
	# not the compact player-crowd layout.
	_visual = RivalCrowdVisualScript.new(_runtime, EnemyModel, null, true, true)
	_visual.position.z = -_engage_distance
	parent.add_child(_visual)


func update(delta: float, ctx: Dictionary) -> Dictionary:
	var distance_to_horde: float = _engage_distance - ctx["distance_traveled"]
	if distance_to_horde > HORDE_SHOOT_RANGE:
		# Not yet in range: the horde sits at its spawned position, visible
		# from a distance like every other pre-spawned encounter but not
		# yet interactable.
		return empty_result()
	if ctx["distance_traveled"] < _engage_distance:
		# Approaching but not yet in contact: shoot it down. A clean kill
		# here costs the player nothing, same reward as clearing an enemy
		# wave before it breaches.
		var feedback: Array = []
		var shots: int = CombatRules.shots_per_volley(ctx["crowd_count"])
		var applied_damage: int = _runtime.apply_shot_damage(
			delta, shots, ctx["distance_traveled"], ctx["crowd_count"]
		)
		if applied_damage > 0:
			feedback.append([&"shot", applied_damage])
		_runtime.advance_bullets(delta, _engage_distance)
		if _runtime.is_defeated():
			feedback.append([&"hit", 1])
		return {"feedback": feedback, "breach_cost": 0}
	# Contact reached with survivors left: identical to a rival crowd's
	# mutual attrition, since apply_shot_damage() and tick() share the same
	# rival_count and tick() doesn't care how that count got where it is.
	# Any bullet still mid-flight from the instant contact was reached
	# loses its narrative meaning (the horde it was headed for is right
	# there now) so it's dropped rather than animated the rest of the way.
	_runtime.bullets.clear()
	if _visual != null and is_instance_valid(_visual):
		_visual.position.z = ctx["crowd_z"]
	var loss: int = _runtime.tick(delta, ctx["crowd_count"])
	return {"feedback": [], "breach_cost": loss}


func is_complete() -> bool:
	return _runtime.is_defeated()
