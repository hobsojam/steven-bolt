extends Node3D

const RunRules := preload("res://scripts/run_rules.gd")
const Vfx := preload("res://scripts/vfx.gd")
const EnemyModel := preload("res://assets/models/enemy.glb")
const BulletModel := preload("res://assets/models/bullet.glb")

# Bullets are short bright bolts; stretching the instance along the track
# axis turns them into tracer streaks instead of round dots.
const TRACER_STRETCH := 3.0

# Non-interactive extras clustered behind each real enemy so a 1-2 enemy
# wave still reads as a group rather than a lone capsule. Offsets are
# behind (-z) and to the side, in local metres.
const BACKING_OFFSETS: Array[Vector3] = [
	Vector3(-0.55, 0.0, -0.65),
	Vector3(0.6, 0.0, -0.8),
	Vector3(0.05, 0.0, -1.3),
]

# When a real enemy dies its whole cluster (the enemy plus its extras)
# goes down, but staggered so it reads as several men falling in quick
# succession rather than one blob winking out.
const DEATH_STAGGER := 0.07

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
	var cluster: Array[Node3D] = [node]
	for child in node.get_children():
		if child is Node3D:
			cluster.append(child)
	# Capture each model's position in this visual's local space now, before
	# the parent's shrink tween starts skewing its children's transforms.
	var local_positions: Array[Vector3] = []
	for model in cluster:
		local_positions.append(model.global_position - global_position)
	for i in cluster.size():
		_kill_model(cluster[i], local_positions[i], i * DEATH_STAGGER)


func _kill_model(model: Node3D, local_position: Vector3, delay: float) -> void:
	var tween := model.create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_callback(_spawn_death_burst.bind(local_position))
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(model, "scale", Vector3.ZERO, 0.12)


func _spawn_death_burst(local_position: Vector3) -> void:
	Vfx.spawn_burst(self, local_position + Vector3(0.0, 0.7, 0.0), Vfx.KILL_COLOR, 12, 4.0)


func _spawn_enemy_visual(enemy: Dictionary) -> Node3D:
	var model := EnemyModel.instantiate() as Node3D
	model.position = Vector3(RunRules.lane_x(enemy["lane"]), 0.0, -enemy["distance"])
	for offset in BACKING_OFFSETS:
		var backer := EnemyModel.instantiate() as Node3D
		backer.position = offset
		model.add_child(backer)
	add_child(model)
	return model


func _spawn_bullet_visual(bullet: Dictionary) -> Node3D:
	var model := BulletModel.instantiate() as Node3D
	model.position = Vector3(
		RunRules.lane_x(bullet["lane"]) + bullet["offset"], bullet["height"], -bullet["distance"]
	)
	model.scale = Vector3(1.0, 1.0, TRACER_STRETCH)
	return model
