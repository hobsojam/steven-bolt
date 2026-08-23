extends Node3D

const TollWallModel := preload("res://assets/models/toll_wall.glb")


func setup(entry: Dictionary) -> void:
	position = Vector3(0.0, 0.0, -entry["distance"])
	add_child(TollWallModel.instantiate())
	add_child(_build_label(entry["threshold"]))


func _build_label(threshold: int) -> Label3D:
	var label := Label3D.new()
	label.text = str(threshold)
	label.position = Vector3(0.0, 1.52, 0.34)
	label.font_size = 72
	label.pixel_size = 0.01
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.outline_size = 10
	label.modulate = Color.WHITE
	return label
