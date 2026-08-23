extends SceneTree

const MODEL_DIR := "res://assets/models"


func _initialize() -> void:
	var errors: Array[String] = []
	_export_model("crowd_unit", _build_crowd_unit(), errors)
	_export_model("gate_positive", _build_gate(true), errors)
	_export_model("gate_negative", _build_gate(false), errors)
	_export_model("toll_wall", _build_toll_wall(), errors)
	if errors.is_empty():
		print("Generated all low-poly art assets")
		quit(0)
	else:
		for message in errors:
			push_error(message)
		quit(1)


func _export_model(file_name: String, model: MeshInstance3D, errors: Array[String]) -> void:
	var root := Node3D.new()
	root.name = file_name.to_pascal_case()
	root.add_child(model)
	model.owner = root
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var append_error := document.append_from_scene(root, state)
	if append_error != OK:
		errors.append("Could not prepare %s: error %d" % [file_name, append_error])
		root.free()
		return
	var output_path := "%s/%s.glb" % [MODEL_DIR, file_name]
	var write_error := document.write_to_filesystem(state, output_path)
	if write_error != OK:
		errors.append("Could not write %s: error %d" % [output_path, write_error])
	else:
		print("Generated %s" % output_path)
	root.free()


func _build_crowd_unit() -> MeshInstance3D:
	var mesh := ArrayMesh.new()
	var orange := _material("Toy orange", Color("f28c26"), 0.82)
	var orange_dark := _material("Toy orange shadow", Color("c95f18"), 0.88)
	var cream := _material("Face glow", Color("ffe5ad"), 0.72)

	var body := SphereMesh.new()
	body.radius = 0.19
	body.height = 0.58
	body.radial_segments = 8
	body.rings = 5
	_append(mesh, body, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.42, 0.0)), orange)

	var head := SphereMesh.new()
	head.radius = 0.21
	head.height = 0.42
	head.radial_segments = 8
	head.rings = 4
	_append(mesh, head, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.79, -0.015)), orange)

	for side in [-1.0, 1.0]:
		var leg := CylinderMesh.new()
		leg.top_radius = 0.07
		leg.bottom_radius = 0.08
		leg.height = 0.28
		leg.radial_segments = 8
		_append(
			mesh,
			leg,
			Transform3D(Basis.IDENTITY, Vector3(0.095 * side, 0.14, 0.0)),
			orange_dark
		)

		var foot := BoxMesh.new()
		foot.size = Vector3(0.15, 0.09, 0.20)
		_append(
			mesh,
			foot,
			Transform3D(Basis.IDENTITY, Vector3(0.095 * side, 0.045, -0.045)),
			orange_dark
		)

		var arm := CylinderMesh.new()
		arm.top_radius = 0.055
		arm.bottom_radius = 0.065
		arm.height = 0.34
		arm.radial_segments = 6
		var arm_basis := Basis.from_euler(Vector3(deg_to_rad(-58.0), 0.0, deg_to_rad(8.0 * side)))
		_append(
			mesh,
			arm,
			Transform3D(arm_basis, Vector3(0.205 * side, 0.50, -0.11)),
			orange
		)

	var face := BoxMesh.new()
	face.size = Vector3(0.20, 0.12, 0.035)
	_append(mesh, face, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.80, -0.218)), cream)

	var instance := MeshInstance3D.new()
	instance.name = "CrowdUnit"
	instance.mesh = mesh
	return instance


func _build_gate(is_positive: bool) -> MeshInstance3D:
	var mesh := ArrayMesh.new()
	var main_color := Color("42d67b") if is_positive else Color("eb4d5c")
	var dark_color := Color("158f55") if is_positive else Color("9f2637")
	var panel_color := Color("bff5d1") if is_positive else Color("681d2b")
	var accent_color := Color("fff0a5") if is_positive else Color("ffd34e")
	var main := _material("Positive green" if is_positive else "Danger red", main_color, 0.78)
	var dark := _material("Gate shadow", dark_color, 0.86)
	var panel := _material("Number panel", panel_color, 0.82)
	var accent := _material("Gate accent", accent_color, 0.72)

	for side in [-1.0, 1.0]:
		_add_box(mesh, Vector3(0.18, 1.55, 0.22), Vector3(0.64 * side, 0.775, 0.0), main)
		_add_box(mesh, Vector3(0.34, 0.12, 0.42), Vector3(0.64 * side, 0.06, 0.0), dark)
		_add_box(mesh, Vector3(0.23, 0.15, 0.27), Vector3(0.64 * side, 1.59, 0.0), accent)
	_add_box(mesh, Vector3(1.44, 0.26, 0.24), Vector3(0.0, 1.70, 0.0), main)
	_add_box(mesh, Vector3(0.92, 0.50, 0.10), Vector3(0.0, 1.47, 0.13), panel)

	if not is_positive:
		for stripe_index in 4:
			var stripe := BoxMesh.new()
			stripe.size = Vector3(0.22, 0.055, 0.025)
			var stripe_basis := Basis.from_euler(Vector3(0.0, 0.0, deg_to_rad(-25.0)))
			var stripe_x := -0.42 + stripe_index * 0.28
			_append(
				mesh,
				stripe,
				Transform3D(stripe_basis, Vector3(stripe_x, 1.75, 0.135)),
				accent
			)

	var instance := MeshInstance3D.new()
	instance.name = "PositiveGate" if is_positive else "NegativeGate"
	instance.mesh = mesh
	return instance


func _build_toll_wall() -> MeshInstance3D:
	var mesh := ArrayMesh.new()
	var red := _material("Barrier red", Color("c93643"), 0.86)
	var red_dark := _material("Barrier shadow", Color("7f1d2d"), 0.92)
	var red_light := _material("Barrier highlight", Color("ef6570"), 0.78)
	var yellow := _material("Warning yellow", Color("ffd34e"), 0.76)
	var panel := _material("Threshold panel", Color("541927"), 0.90)

	_add_box(mesh, Vector3(0.34, 2.90, 0.46), Vector3(-3.82, 1.45, 0.0), red_dark)
	_add_box(mesh, Vector3(0.34, 2.90, 0.46), Vector3(3.82, 1.45, 0.0), red_dark)

	for row in 3:
		for column in 8:
			var block_x := -3.40 + column * 0.97 + (0.24 if row % 2 == 1 else 0.0)
			if block_x > 3.45:
				continue
			var block_color := red_light if (row + column) % 3 == 0 else red
			_add_box(
				mesh,
				Vector3(0.91, 0.58, 0.38),
				Vector3(block_x, 0.34 + row * 0.60, 0.0),
				block_color
			)

	_add_box(mesh, Vector3(7.20, 0.22, 0.48), Vector3(0.0, 2.12, 0.0), red_dark)
	for tooth in 8:
		_add_box(
			mesh,
			Vector3(0.56, 0.50, 0.42),
			Vector3(-3.40 + tooth * 0.97, 2.45, 0.0),
			red
		)

	_add_box(mesh, Vector3(2.35, 0.88, 0.12), Vector3(0.0, 1.52, 0.26), panel)
	_add_box(mesh, Vector3(2.62, 0.12, 0.16), Vector3(0.0, 1.98, 0.29), yellow)
	_add_box(mesh, Vector3(2.62, 0.12, 0.16), Vector3(0.0, 1.06, 0.29), yellow)

	var instance := MeshInstance3D.new()
	instance.name = "TollWall"
	instance.mesh = mesh
	return instance


func _add_box(
	target: ArrayMesh,
	size: Vector3,
	position: Vector3,
	material: StandardMaterial3D
) -> void:
	var box := BoxMesh.new()
	box.size = size
	_append(target, box, Transform3D(Basis.IDENTITY, position), material)


func _append(
	target: ArrayMesh,
	source: PrimitiveMesh,
	transform: Transform3D,
	material: StandardMaterial3D
) -> void:
	var surface := SurfaceTool.new()
	surface.set_material(material)
	surface.append_from(source, 0, transform)
	surface.commit(target)


func _material(label: String, color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.resource_name = label
	# StandardMaterial3D stores albedo in linear space; authored palette values
	# are conventional sRGB hex colors.
	material.albedo_color = color.srgb_to_linear()
	material.roughness = roughness
	return material
