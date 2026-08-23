extends Node3D

const RunRules := preload("res://scripts/run_rules.gd")


func setup(entry: Dictionary) -> void:
	position = Vector3(0.0, 1.5, -entry["distance"])
	var lanes: Array = entry["lanes"]
	for lane_index in lanes.size():
		var lane_data: Dictionary = lanes[lane_index]
		add_child(_build_label(lane_index, lane_data))


func _build_label(lane_index: int, lane_data: Dictionary) -> Label3D:
	var label := Label3D.new()
	label.text = "%s%d" % [lane_data["op"], lane_data["value"]]
	label.position = Vector3(RunRules.lane_x(lane_index), 0.0, 0.0)
	label.font_size = 48
	label.pixel_size = 0.01
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color.WHITE if lane_data["op"] == "+" else Color(1.0, 0.4, 0.4)
	return label
