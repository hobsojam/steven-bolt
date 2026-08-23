extends Node3D

const RunRules := preload("res://scripts/run_rules.gd")

var current_lane: int = RunRules.LANE_COUNT / 2
var crowd_count: int = RunRules.START_CROWD_COUNT

var _drag_active: bool = false
var _drag_start_x: float = 0.0


func _ready() -> void:
	position.x = RunRules.lane_x(current_lane)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("lane_left"):
		move_lane(-1)
	elif event.is_action_pressed("lane_right"):
		move_lane(1)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_drag_active = event.pressed
		_drag_start_x = event.position.x
	elif event is InputEventMouseMotion and _drag_active:
		var delta_x: float = event.position.x - _drag_start_x
		if absf(delta_x) >= RunRules.SWIPE_THRESHOLD_PX:
			move_lane(1 if delta_x > 0.0 else -1)
			_drag_start_x = event.position.x


func move_lane(direction: int) -> void:
	current_lane = clampi(current_lane + direction, 0, RunRules.LANE_COUNT - 1)


func apply_gate(op: String, value: int) -> void:
	crowd_count = RunRules.apply_gate(crowd_count, op, value)


func _process(delta: float) -> void:
	var target_x: float = RunRules.lane_x(current_lane)
	position.x = move_toward(position.x, target_x, RunRules.LANE_SWITCH_SPEED * delta)
