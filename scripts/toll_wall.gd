extends Node3D

const RunRules := preload("res://scripts/run_rules.gd")


func setup(entry: Dictionary) -> void:
	position = Vector3(0.0, 0.0, -entry["distance"])
	add_child(_build_wall())
	add_child(_build_label(entry["threshold"]))


func _build_wall() -> MeshInstance3D:
	var wall := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(RunRules.CROWD_MAX_WIDTH + 2.0, 3.0, 0.2)
	wall.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.7, 0.15, 0.15, 0.85)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wall.material_override = material
	wall.position = Vector3(0.0, 1.5, 0.0)
	return wall


func _build_label(threshold: int) -> Label3D:
	var label := Label3D.new()
	label.text = str(threshold)
	label.position = Vector3(0.0, 1.5, 0.1)
	label.font_size = 96
	label.pixel_size = 0.02
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color.WHITE
	return label
