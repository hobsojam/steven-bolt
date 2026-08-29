extends Node3D

const RunRules := preload("res://scripts/run_rules.gd")
const Vfx := preload("res://scripts/vfx.gd")
const BulletModel := preload("res://assets/models/bullet.glb")

# Cadence for the "shredding line" - one spark burst per this many
# seconds while the mass is losing units, so a fast attrition tick doesn't
# spawn a burst every frame.
const SHRED_INTERVAL := 0.06
const TRACER_STRETCH := 3.0

var runtime
var _model: PackedScene
var _tint
var _face_player: bool
# A horde renders as a full-width mass receding toward the horizon
# (RunRules.enemy_mass_layout); a plain rival crowd reuses the compact
# player-crowd layout.
var _is_mass: bool

var _last_count: int = -1
var _shred_seen_count: int = -1
var _shred_cooldown: float = 0.0
var _multimesh_instance: MultiMeshInstance3D
var _bullet_container: Node3D


func _init(
	crowd_runtime, model: PackedScene, tint, face_player: bool, mass: bool = false
) -> void:
	runtime = crowd_runtime
	_model = model
	_tint = tint
	_face_player = face_player
	_is_mass = mass


func _ready() -> void:
	_multimesh_instance = MultiMeshInstance3D.new()
	var mesh := MultiMesh.new()
	mesh.transform_format = MultiMesh.TRANSFORM_3D
	mesh.instance_count = 0
	var model_root := _model.instantiate()
	var model_mesh := _find_mesh_instance(model_root)
	if model_mesh != null:
		mesh.mesh = model_mesh.mesh
	model_root.free()
	_multimesh_instance.multimesh = mesh
	if _tint != null:
		# A distinct tint overriding the model's own per-part materials
		# uniformly - lets this visual reuse an existing model (e.g. the
		# crowd unit for a rival crowd) rather than needing a dedicated one.
		# Pass null to use the model's own baked material as-is instead
		# (e.g. the enemy model already has its own danger-red material).
		var material := StandardMaterial3D.new()
		material.albedo_color = _tint
		_multimesh_instance.material_override = material
	add_child(_multimesh_instance)
	_bullet_container = Node3D.new()
	add_child(_bullet_container)


func _process(delta: float) -> void:
	var count: int = runtime.rival_count
	if count != _last_count:
		_last_count = count
		_rebuild(count)
	_refresh_bullets()
	_emit_shred(count, delta)


func _emit_shred(count: int, delta: float) -> void:
	_shred_cooldown = maxf(_shred_cooldown - delta, 0.0)
	if _shred_seen_count < 0:
		_shred_seen_count = count
		return
	if count >= _shred_seen_count:
		return
	var lost: int = _shred_seen_count - count
	_shred_seen_count = count
	if _shred_cooldown > 0.0:
		return
	_shred_cooldown = SHRED_INTERVAL
	# Front rank sits at local z = 0 (the face turned toward the player),
	# where fire is landing.
	var half_width: float = maxf(_front_half_width(count), 0.4)
	Vfx.spawn_burst(
		self,
		Vector3(randf_range(-half_width, half_width), 1.0, 0.0),
		Vfx.KILL_COLOR,
		clampi(lost * 3, 8, 26),
		3.5
	)


func _refresh_bullets() -> void:
	for child in _bullet_container.get_children():
		child.queue_free()
	for bullet in runtime.bullets:
		var model := BulletModel.instantiate() as Node3D
		# bullet["distance"] is an absolute world distance (matching the
		# convention everywhere else - crowd_controller, gates, enemy_wave
		# bullets). This node itself sits at -engage_distance in world space
		# (see run_controller.gd's spawn code), so a child's local z needs
		# the parent's own offset subtracted back out to land at the
		# intended world position instead of stacking on top of it.
		model.position = Vector3(bullet["offset"], bullet["height"], -bullet["distance"] - position.z)
		model.scale = Vector3(1.0, 1.0, TRACER_STRETCH)
		_bullet_container.add_child(model)


func _front_half_width(count: int) -> float:
	if _is_mass:
		return RunRules.ENEMY_MASS_WIDTH / 2.0
	return RunRules.crowd_front_edge_half_width(count)


func _rebuild(count: int) -> void:
	var transforms: Array[Transform3D] = (
		RunRules.build_enemy_mass_transforms(count)
		if _is_mass
		else RunRules.build_multimesh_transforms(count)
	)
	_multimesh_instance.multimesh.instance_count = transforms.size()
	if _face_player:
		# Face the player's crowd (the model's own forward is -Z, matching
		# the player's facing direction, so facing it needs a 180-degree
		# turn) rather than facing away, for a more confrontational read.
		var facing_player := Basis(Vector3.UP, PI)
		for i in transforms.size():
			var instance_transform: Transform3D = transforms[i]
			instance_transform.basis = facing_player * instance_transform.basis
			_multimesh_instance.multimesh.set_instance_transform(i, instance_transform)
	else:
		for i in transforms.size():
			_multimesh_instance.multimesh.set_instance_transform(i, transforms[i])


func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node as MeshInstance3D
	for child in node.get_children():
		var result := _find_mesh_instance(child)
		if result != null:
			return result
	return null
