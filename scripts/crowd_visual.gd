extends Node3D

const RunRules := preload("res://scripts/run_rules.gd")
const CrowdUnitModel := preload("res://assets/models/crowd_unit.glb")

var _last_crowd_count: int = -1

@onready var _crowd = get_parent()
@onready var _multimesh_instance: MultiMeshInstance3D = $MultiMeshInstance3D


func _ready() -> void:
	var model_root := CrowdUnitModel.instantiate()
	var model_mesh := _find_mesh_instance(model_root)
	if model_mesh == null:
		push_error("crowd_unit.glb does not contain a MeshInstance3D")
	else:
		_multimesh_instance.multimesh.mesh = model_mesh.mesh
	model_root.free()


func _process(_delta: float) -> void:
	var count: int = _crowd.crowd_count
	if count == _last_crowd_count:
		return
	_last_crowd_count = count
	_rebuild(count)


func _rebuild(count: int) -> void:
	var transforms: Array[Transform3D] = RunRules.build_multimesh_transforms(count)
	var mesh: MultiMesh = _multimesh_instance.multimesh
	mesh.instance_count = transforms.size()
	for i in transforms.size():
		mesh.set_instance_transform(i, transforms[i])


func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node as MeshInstance3D
	for child in node.get_children():
		var result := _find_mesh_instance(child)
		if result != null:
			return result
	return null
