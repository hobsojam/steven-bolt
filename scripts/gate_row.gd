extends Node3D

const RunRules := preload("res://scripts/run_rules.gd")
const PositiveGateModel := preload("res://assets/models/gate_positive.glb")
const NegativeGateModel := preload("res://assets/models/gate_negative.glb")

const GAIN_COLOR := Color("42d67b")
const LOSS_COLOR := Color("eb4d5c")

var _entry: Dictionary = {}
var _gate_nodes: Array[Node3D] = []
var _crowd: Node3D = null
var _punched: bool = false


func setup(entry: Dictionary) -> void:
	_entry = entry
	position = Vector3(0.0, 0.0, -entry["distance"])
	var lanes: Array = entry["lanes"]
	for lane_index in lanes.size():
		var lane_data: Dictionary = lanes[lane_index]
		var gate := _build_gate(lane_index, lane_data)
		_gate_nodes.append(gate)
		add_child(gate)
		add_child(_build_label(lane_index, lane_data))


func _ready() -> void:
	_crowd = get_node_or_null("../CrowdController")


func _process(_delta: float) -> void:
	# Punch the lane the crowd actually ran through, once, as it crosses.
	if _punched or _crowd == null:
		return
	if _crowd.global_position.z <= global_position.z:
		_punched = true
		_punch_lane(_crowd.current_lane)


func _punch_lane(lane_index: int) -> void:
	if lane_index < 0 or lane_index >= _gate_nodes.size():
		return
	var gate: Node3D = _gate_nodes[lane_index]
	gate.scale = Vector3(1.18, 0.86, 1.18)
	var tween := gate.create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(gate, "scale", Vector3.ONE, 0.24)
	_float_number(lane_index, _entry["lanes"][lane_index])


func _float_number(lane_index: int, lane_data: Dictionary) -> void:
	var label := Label3D.new()
	label.text = "%s%d" % [lane_data["op"], lane_data["value"]]
	label.font_size = 64
	label.pixel_size = 0.012
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.outline_size = 10
	label.modulate = GAIN_COLOR if lane_data["op"] == "+" else LOSS_COLOR
	label.position = Vector3(RunRules.lane_x(lane_index), 1.8, 0.3)
	add_child(label)
	var tween := label.create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:y", 3.4, 0.6)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6)
	tween.tween_callback(label.queue_free)


func _build_gate(lane_index: int, lane_data: Dictionary) -> Node3D:
	var packed_model: PackedScene = (
		PositiveGateModel if lane_data["op"] == "+" else NegativeGateModel
	)
	var gate := packed_model.instantiate() as Node3D
	gate.position.x = RunRules.lane_x(lane_index)
	return gate


func _build_label(lane_index: int, lane_data: Dictionary) -> Label3D:
	var label := Label3D.new()
	label.text = "%s%d" % [lane_data["op"], lane_data["value"]]
	label.position = Vector3(RunRules.lane_x(lane_index), 1.47, 0.22)
	label.font_size = 56
	label.pixel_size = 0.01
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.outline_size = 8
	label.modulate = Color.WHITE if lane_data["op"] == "+" else Color("fff0a5")
	return label
