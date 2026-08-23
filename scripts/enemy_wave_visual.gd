extends Node3D

const RunRules := preload("res://scripts/run_rules.gd")

var runtime

var _enemy_nodes: Array[MeshInstance3D] = []
var _bullet_container: Node3D


func _init(wave_runtime) -> void:
	runtime = wave_runtime


func _ready() -> void:
	_bullet_container = Node3D.new()
	add_child(_bullet_container)
	for enemy in runtime.enemies:
		_enemy_nodes.append(_spawn_enemy_visual(enemy))


func _process(_delta: float) -> void:
	for i in runtime.enemies.size():
		_enemy_nodes[i].visible = runtime.enemies[i]["alive"]
	for child in _bullet_container.get_children():
		child.queue_free()
	for bullet in runtime.bullets:
		_bullet_container.add_child(_spawn_bullet_visual(bullet))


func _spawn_enemy_visual(enemy: Dictionary) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.7, 1.2, 0.5)
	mesh_instance.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("8b2fc9")
	mesh_instance.material_override = material
	mesh_instance.position = Vector3(RunRules.lane_x(enemy["lane"]), 0.6, -enemy["distance"])
	add_child(mesh_instance)
	return mesh_instance


func _spawn_bullet_visual(bullet: Dictionary) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.12
	sphere.height = 0.24
	mesh_instance.mesh = sphere
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("fff59d")
	material.emission_enabled = true
	material.emission = Color("fff59d")
	mesh_instance.material_override = material
	mesh_instance.position = Vector3(RunRules.lane_x(bullet["lane"]), 1.0, -bullet["distance"])
	return mesh_instance
