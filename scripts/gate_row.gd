extends Node3D

const RunRules := preload("res://scripts/run_rules.gd")
const PositiveGateModel := preload("res://assets/models/gate_positive.glb")
const NegativeGateModel := preload("res://assets/models/gate_negative.glb")


func setup(entry: Dictionary) -> void:
	position = Vector3(0.0, 0.0, -entry["distance"])
	var lanes: Array = entry["lanes"]
	for lane_index in lanes.size():
		var lane_data: Dictionary = lanes[lane_index]
		add_child(_build_gate(lane_index, lane_data))
		add_child(_build_label(lane_index, lane_data))


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
