extends "res://scripts/encounter.gd"

# A rival crowd: an enemy crowd blocking the track that resolves by
# mutual attrition on contact - both sides tick down together until one
# hits zero, converging on the same survivor count an instant 1-for-1
# subtraction would give. Engaged the moment the crowd reaches its
# distance; the attrition math is rival_crowd_runtime.gd's tick().

const RivalCrowdRuntimeScript := preload("res://scripts/rival_crowd_runtime.gd")
const RivalCrowdVisualScript := preload("res://scripts/rival_crowd_visual.gd")
const CrowdUnitModel := preload("res://assets/models/crowd_unit.glb")

var _runtime = null
var _engage_distance: float = 0.0


func _init(entry: Dictionary) -> void:
	super(entry)
	_runtime = RivalCrowdRuntimeScript.new(entry["count"])
	_engage_distance = entry["distance"]


func spawn(parent: Node3D) -> void:
	_visual = RivalCrowdVisualScript.new(
		_runtime, CrowdUnitModel, Color("3a6ea5").srgb_to_linear(), true
	)
	_visual.position.z = -_engage_distance
	parent.add_child(_visual)


func update(delta: float, ctx: Dictionary) -> Dictionary:
	if ctx["distance_traveled"] < _engage_distance:
		return empty_result()
	# Motion never stops elsewhere in this game, so once engaged the rival
	# visual tracks the crowd's own Z every frame instead of staying at
	# its spawned position - "crowds mashed together fighting" rather than
	# the crowd visibly running past a stationary rival mid-battle.
	if _visual != null and is_instance_valid(_visual):
		_visual.position.z = ctx["crowd_z"]
	var loss: int = _runtime.tick(delta, ctx["crowd_count"])
	return {"feedback": [], "breach_cost": loss}


func is_complete() -> bool:
	return _runtime.is_defeated()
