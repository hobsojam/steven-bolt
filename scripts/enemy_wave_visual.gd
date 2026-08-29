extends Node3D

const RunRules := preload("res://scripts/run_rules.gd")
const Vfx := preload("res://scripts/vfx.gd")
const EnemyModel := preload("res://assets/models/enemy.glb")
const BulletModel := preload("res://assets/models/bullet.glb")

# Bullets are short bright bolts; stretching the instance along the track
# axis turns them into tracer streaks instead of round dots.
const TRACER_STRETCH := 3.0

var runtime

var _enemy_nodes: Array[Node3D] = []
var _enemy_alive: Array[bool] = []
var _bullet_container: Node3D


func _init(wave_runtime) -> void:
	runtime = wave_runtime


func _ready() -> void:
	_bullet_container = Node3D.new()
	add_child(_bullet_container)
	for enemy in runtime.enemies:
		_enemy_nodes.append(_spawn_enemy_visual(enemy))
		_enemy_alive.append(true)


func _process(_delta: float) -> void:
	for i in runtime.enemies.size():
		var alive: bool = runtime.enemies[i]["alive"]
		if alive:
			_enemy_nodes[i].visible = true
		elif _enemy_alive[i]:
			# alive -> dead this frame (shot down or breached): play it out
			# rather than snapping the model to invisible.
			_enemy_alive[i] = false
			_play_death(i)
	for child in _bullet_container.get_children():
		child.queue_free()
	for bullet in runtime.bullets:
		_bullet_container.add_child(_spawn_bullet_visual(bullet))


func _play_death(index: int) -> void:
	var node: Node3D = _enemy_nodes[index]
	Vfx.spawn_burst(self, node.position + Vector3(0.0, 0.7, 0.0), Vfx.KILL_COLOR, 16, 4.5)
	var tween := node.create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(node, "scale", Vector3.ZERO, 0.14)
	tween.tween_callback(node.hide)


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
	model.scale = Vector3(1.0, 1.0, TRACER_STRETCH)
	return model
