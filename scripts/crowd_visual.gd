extends Node3D

const RunRules := preload("res://scripts/run_rules.gd")

var _last_crowd_count: int = -1

@onready var _crowd = get_parent()
@onready var _multimesh_instance: MultiMeshInstance3D = $MultiMeshInstance3D


func _process(_delta: float) -> void:
	var count: int = _crowd.crowd_count
	if count == _last_crowd_count:
		return
	_last_crowd_count = count
	_rebuild(count)


func _rebuild(count: int) -> void:
	var positions: Array[Vector3] = RunRules.crowd_layout(count)
	var mesh: MultiMesh = _multimesh_instance.multimesh
	mesh.instance_count = positions.size()
	for i in positions.size():
		mesh.set_instance_transform(i, Transform3D(Basis(), positions[i]))
