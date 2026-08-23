extends Node3D

enum RunState { RUNNING, GAME_OVER }

const RunRules := preload("res://scripts/run_rules.gd")
const LevelOneDefinition := preload("res://scripts/level_one_definition.gd")

var distance_traveled: float = 0.0
var _state: int = RunState.RUNNING
var _level_entries: Array[Dictionary] = []
var _next_entry_index: int = 0

@onready var _crowd = $CrowdController


func _ready() -> void:
	_level_entries = LevelOneDefinition.entries()


func _process(delta: float) -> void:
	if _state != RunState.RUNNING:
		if Input.is_action_just_pressed("ui_accept"):
			get_tree().reload_current_scene()
		return
	distance_traveled += RunRules.RUN_SPEED * delta
	_crowd.position.z = -distance_traveled
	_resolve_pending_entries()


func is_game_over() -> bool:
	return _state == RunState.GAME_OVER


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
			_crowd.apply_gate(lane_data["op"], lane_data["value"])
			if _crowd.crowd_count <= 0:
				_state = RunState.GAME_OVER
