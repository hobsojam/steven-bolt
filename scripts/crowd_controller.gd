extends Node3D

signal lane_changed(lane: int, direction: int)

const RunRules := preload("res://scripts/run_rules.gd")

var current_lane: int = RunRules.LANE_COUNT / 2
var crowd_count: int = RunRules.START_CROWD_COUNT

var _drag_active: bool = false
var _drag_start_x: float = 0.0
var _drag_pointer_id: int = -1
var _lane_kick_tween: Tween

@onready var _crowd_visual: Node3D = $CrowdVisual


func _ready() -> void:
	position.x = RunRules.lane_x(current_lane)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("lane_left"):
		move_lane(-1)
	elif event.is_action_pressed("lane_right"):
		move_lane(1)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_begin_drag(event.position.x, -1)
		else:
			_end_drag(-1)
	elif event is InputEventMouseMotion and _drag_active and _drag_pointer_id == -1:
		_consume_drag(event.position.x)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_begin_drag(event.position.x, event.index)
		else:
			_end_drag(event.index)
	elif (
		event is InputEventScreenDrag
		and _drag_active
		and event.index == _drag_pointer_id
	):
		_consume_drag(event.position.x)


func _begin_drag(pointer_x: float, pointer_id: int) -> void:
	_drag_active = true
	_drag_start_x = pointer_x
	_drag_pointer_id = pointer_id


func _end_drag(pointer_id: int) -> void:
	if pointer_id != _drag_pointer_id:
		return
	_drag_active = false
	_drag_pointer_id = -1


func _consume_drag(pointer_x: float) -> void:
	var lane_steps: int = RunRules.lane_steps_from_drag(pointer_x - _drag_start_x)
	if lane_steps == 0:
		return
	move_lane(lane_steps)
	# Consume whole thresholds but retain any remainder. This keeps a large
	# drag proportional and prevents a blocked edge swipe from building up a
	# hidden movement that fires when the player reverses direction.
	_drag_start_x += lane_steps * RunRules.SWIPE_THRESHOLD_PX


func move_lane(direction: int) -> void:
	var next_lane: int = RunRules.clamped_lane(current_lane, direction)
	if next_lane == current_lane:
		return
	var move_direction: int = signi(next_lane - current_lane)
	current_lane = next_lane
	# The root position is authoritative for both visuals and gameplay. Snap it
	# immediately so a gate can never resolve against a lane the crowd has not
	# visibly reached, then settle a small within-lane lean for feel.
	position.x = RunRules.lane_x(current_lane)
	_play_lane_lean(move_direction)
	lane_changed.emit(current_lane, move_direction)


func _play_lane_lean(direction: int) -> void:
	if _lane_kick_tween and _lane_kick_tween.is_valid():
		_lane_kick_tween.kill()
	# A brief trailing offset + bank that eases straight back to neutral.
	# No overshoot (TRANS_QUART, not TRANS_BACK) - it should read as the
	# crowd leaning into the move, not springing.
	_crowd_visual.position.x = -direction * 0.12
	_crowd_visual.rotation.z = -direction * 0.05
	_lane_kick_tween = create_tween().set_parallel(true)
	_lane_kick_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_lane_kick_tween.tween_property(_crowd_visual, "position:x", 0.0, 0.16)
	_lane_kick_tween.tween_property(_crowd_visual, "rotation:z", 0.0, 0.16)


func apply_gate(op: String, value: int) -> void:
	crowd_count = RunRules.apply_gate(crowd_count, op, value)


func apply_toll(threshold: int) -> bool:
	if not RunRules.can_pass_toll(crowd_count, threshold):
		return false
	crowd_count = RunRules.apply_toll(crowd_count, threshold)
	return true


func apply_breach(cost: int) -> void:
	crowd_count = RunRules.apply_gate(crowd_count, "-", cost)
