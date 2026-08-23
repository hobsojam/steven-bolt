extends Node3D

const RunRules := preload("res://scripts/run_rules.gd")


func setup(entry: Dictionary) -> void:
	position = Vector3(RunRules.lane_x(entry["lane"]), 1.1, -entry["distance"])
	add_child(_build_label(entry["op"], entry["value"]))


func _build_label(op: String, value: int) -> Label3D:
	var label := Label3D.new()
	label.text = "%s%d" % [op, value]
	label.font_size = 40
	label.pixel_size = 0.008
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.outline_size = 6
	label.modulate = Color("fff0a5") if op == "+" else Color("ff6666")
	return label
