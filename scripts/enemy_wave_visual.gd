extends Node3D

const RunRules := preload("res://scripts/run_rules.gd")
const EnemyModel := preload("res://assets/models/enemy.glb")
const BulletModel := preload("res://assets/models/bullet.glb")

var runtime

var _enemy_nodes: Array[Node3D] = []
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


func _spawn_enemy_visual(enemy: Dictionary) -> Node3D:
	var model := EnemyModel.instantiate() as Node3D
	model.position = Vector3(RunRules.lane_x(enemy["lane"]), 0.0, -enemy["distance"])
	add_child(model)
	return model


func _spawn_bullet_visual(bullet: Dictionary) -> Node3D:
	var model := BulletModel.instantiate() as Node3D
	model.position = Vector3(
		RunRules.lane_x(bullet["lane"]) + bullet["offset"], bullet["height"], -bullet["distance"]
	)
	return model
