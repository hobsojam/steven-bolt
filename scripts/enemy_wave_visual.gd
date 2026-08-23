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
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.3
	capsule.height = 1.4
	mesh_instance.mesh = capsule
	var material := StandardMaterial3D.new()
	# StandardMaterial3D albedo is linear-space; the authored value is a
	# conventional sRGB hex, matching the "Barrier red" danger color used
	# for the toll wall/negative gates (see tools/generate_art_assets.gd).
	material.albedo_color = Color("c93643").srgb_to_linear()
	mesh_instance.material_override = material
	mesh_instance.position = Vector3(RunRules.lane_x(enemy["lane"]), 0.7, -enemy["distance"])
	add_child(mesh_instance)
	return mesh_instance


func _spawn_bullet_visual(bullet: Dictionary) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.12
	sphere.height = 0.24
	mesh_instance.mesh = sphere
	var material := StandardMaterial3D.new()
	var bullet_color := Color("fff59d").srgb_to_linear()
	material.albedo_color = bullet_color
	material.emission_enabled = true
	material.emission = bullet_color
	mesh_instance.material_override = material
	mesh_instance.position = Vector3(RunRules.lane_x(bullet["lane"]), 1.0, -bullet["distance"])
	return mesh_instance
