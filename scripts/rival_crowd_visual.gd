extends Node3D

const RunRules := preload("res://scripts/run_rules.gd")
const CrowdUnitModel := preload("res://assets/models/crowd_unit.glb")

var runtime

var _last_rival_count: int = -1
var _multimesh_instance: MultiMeshInstance3D


func _init(rival_runtime) -> void:
	runtime = rival_runtime


func _ready() -> void:
	_multimesh_instance = MultiMeshInstance3D.new()
	var mesh := MultiMesh.new()
	mesh.transform_format = MultiMesh.TRANSFORM_3D
	mesh.instance_count = 0
	var model_root := CrowdUnitModel.instantiate()
	var model_mesh := _find_mesh_instance(model_root)
	if model_mesh != null:
		mesh.mesh = model_mesh.mesh
	model_root.free()
	_multimesh_instance.multimesh = mesh
	var material := StandardMaterial3D.new()
	# A distinct "rival" tint overriding the model's own per-part materials
	# uniformly - reuses the player's crowd model rather than needing a new
	# one to ship the mechanic; a dedicated rival-unit model is a natural
	# future ART_SPEC.md addendum.
	material.albedo_color = Color("3a6ea5").srgb_to_linear()
	_multimesh_instance.material_override = material
	add_child(_multimesh_instance)


func _process(_delta: float) -> void:
	var count: int = runtime.rival_count
	if count == _last_rival_count:
		return
	_last_rival_count = count
	_rebuild(count)


func _rebuild(count: int) -> void:
	var transforms: Array[Transform3D] = RunRules.build_multimesh_transforms(count)
	# Face the player's crowd (the model's own forward is -Z, matching the
	# player's facing direction, so a rival needs a 180-degree turn) rather
	# than facing away, for a more confrontational read.
	var facing_player := Basis(Vector3.UP, PI)
	_multimesh_instance.multimesh.instance_count = transforms.size()
	for i in transforms.size():
		var instance_transform: Transform3D = transforms[i]
		instance_transform.basis = facing_player * instance_transform.basis
		_multimesh_instance.multimesh.set_instance_transform(i, instance_transform)


func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node as MeshInstance3D
	for child in node.get_children():
		var result := _find_mesh_instance(child)
		if result != null:
			return result
	return null
