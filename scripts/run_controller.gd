extends Node3D

signal feedback_requested(kind: StringName, amount: int)
signal run_state_changed(state: int)

enum RunState { START, RUNNING, GAME_OVER, FINISHED }

const RunRules := preload("res://scripts/run_rules.gd")
const LevelOneDefinition := preload("res://scripts/level_one_definition.gd")
const GateRowScript := preload("res://scripts/gate_row.gd")
const TollWallScript := preload("res://scripts/toll_wall.gd")
const PickupScript := preload("res://scripts/pickup.gd")
const EncounterFactory := preload("res://scripts/encounter_factory.gd")

var distance_traveled: float = 0.0
var _elapsed_time: float = 0.0
var _state: int = RunState.START
var _level_entries: Array[Dictionary] = []
var _next_entry_index: int = 0
# Encounters (enemy waves, hordes, rival crowds) are level entries that
# live and update over many frames rather than resolving instantly when
# crossed. Each one hides its own runtime + visual + phase logic behind
# encounter.gd's lifecycle; this controller only spawns them, forwards a
# per-frame context, and applies the feedback / breach result they hand
# back. See encounter.gd for how to add a new encounter type.
var _encounters: Array = []

@onready var _crowd = $CrowdController


func _ready() -> void:
	_level_entries = LevelOneDefinition.entries()
	_spawn_level_visuals()


func _process(delta: float) -> void:
	if _state == RunState.START:
		if Input.is_action_just_pressed("ui_accept"):
			_set_state(RunState.RUNNING)
		return
	if _state != RunState.RUNNING:
		if Input.is_action_just_pressed("ui_accept"):
			get_tree().reload_current_scene()
		return
	_elapsed_time += delta
	distance_traveled += RunRules.current_speed(_elapsed_time) * delta
	_crowd.position.z = -distance_traveled
	_resolve_pending_entries()
	_update_encounters(delta)
	if _state == RunState.RUNNING and distance_traveled >= LevelOneDefinition.length():
		_emit_feedback(&"complete")
		_set_state(RunState.FINISHED)


func is_start() -> bool:
	return _state == RunState.START


func is_game_over() -> bool:
	return _state == RunState.GAME_OVER


func is_finished() -> bool:
	return _state == RunState.FINISHED


func _set_state(next_state: int) -> void:
	if next_state == _state:
		return
	_state = next_state
	run_state_changed.emit(_state)


func _emit_feedback(kind: StringName, amount: int = 0) -> void:
	feedback_requested.emit(kind, amount)


func _resolve_pending_entries() -> void:
	while (
		_next_entry_index < _level_entries.size()
		and distance_traveled >= _level_entries[_next_entry_index]["distance"]
	):
		_resolve_entry(_level_entries[_next_entry_index])
		_next_entry_index += 1
		if _state != RunState.RUNNING:
			return


func _resolve_entry(entry: Dictionary) -> void:
	match entry["kind"]:
		"gate_row":
			var lane_data: Dictionary = entry["lanes"][_crowd.current_lane]
			var previous_count: int = _crowd.crowd_count
			_crowd.apply_gate(lane_data["op"], lane_data["value"])
			if _crowd.crowd_count <= 0:
				_emit_feedback(&"failure", previous_count)
				_set_state(RunState.GAME_OVER)
			elif _crowd.crowd_count > previous_count:
				_emit_feedback(&"gate_gain", _crowd.crowd_count - previous_count)
			elif _crowd.crowd_count < previous_count:
				_emit_feedback(&"gate_loss", previous_count - _crowd.crowd_count)
		"toll_wall":
			if not _crowd.apply_toll(entry["threshold"]):
				_emit_feedback(&"toll_fail", entry["threshold"])
				_set_state(RunState.GAME_OVER)
			else:
				_emit_feedback(&"toll_pass", entry["threshold"])
		"pickup":
			if _crowd.current_lane == entry["lane"]:
				var previous_count: int = _crowd.crowd_count
				_crowd.apply_gate(entry["op"], entry["value"])
				var difference: int = _crowd.crowd_count - previous_count
				if difference > 0:
					_emit_feedback(&"pickup_gain", difference)
				elif difference < 0:
					_emit_feedback(&"pickup_loss", -difference)


func _update_encounters(delta: float) -> void:
	if _encounters.is_empty():
		return
	var context := {
		"crowd_count": _crowd.crowd_count,
		"current_lane": _crowd.current_lane,
		"distance_traveled": distance_traveled,
		"crowd_z": _crowd.position.z,
	}
	var still_active: Array = []
	for encounter in _encounters:
		var result: Dictionary = encounter.update(delta, context)
		for event in result["feedback"]:
			_emit_feedback(event[0], event[1])
		var breach_cost: int = result["breach_cost"]
		if breach_cost > 0:
			_crowd.apply_breach(breach_cost)
			if _crowd.crowd_count <= 0:
				_emit_feedback(&"failure", breach_cost)
				_set_state(RunState.GAME_OVER)
			else:
				_emit_feedback(&"damage", breach_cost)
		if encounter.is_complete():
			encounter.cleanup()
		else:
			still_active.append(encounter)
	_encounters = still_active


func _spawn_level_visuals() -> void:
	for entry in _level_entries:
		if EncounterFactory.is_encounter(entry["kind"]):
			# Unlike gate_row / toll_wall / pickup (resolved once, instantly,
			# when crossed), an encounter exists and is simulated from level
			# start - same as gates being visible from a distance via the
			# chase camera's lookahead, rather than popping in right before
			# the crowd reaches it.
			var encounter = EncounterFactory.create(entry)
			encounter.spawn(self)
			_encounters.append(encounter)
			continue
		var visual
		match entry["kind"]:
			"gate_row":
				visual = GateRowScript.new()
			"toll_wall":
				visual = TollWallScript.new()
			"pickup":
				visual = PickupScript.new()
		if visual:
			add_child(visual)
			visual.setup(entry)
