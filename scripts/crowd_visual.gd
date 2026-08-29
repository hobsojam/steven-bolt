extends Node3D

const RunRules := preload("res://scripts/run_rules.gd")
const CrowdUnitModel := preload("res://assets/models/crowd_unit.glb")

const SHADOW_MARGIN := 0.9

var _last_crowd_count: int = -1
var _shadow: MeshInstance3D

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
	_build_shadow()


func _build_shadow() -> void:
	# A soft dark blob under the crowd so it reads as planted, not
	# floating. Cheap stand-in for ground AO: one unshaded, alpha-blended
	# quad with a procedurally generated radial-falloff texture (no asset,
	# and GL Compatibility has no decals). Sized to the crowd each rebuild.
	_shadow = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	_shadow.mesh = quad
	_shadow.rotation_degrees.x = -90.0
	_shadow.position.y = 0.02  # lift off the road to avoid z-fighting
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.0, 0.0, 0.0, 0.34)
	material.albedo_texture = _make_blob_texture()
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_shadow.material_override = material
	_shadow.visible = false
	add_child(_shadow)


func _make_blob_texture() -> ImageTexture:
	var size := 64
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size, size) * 0.5
	var max_distance := size * 0.5
	for y in size:
		for x in size:
			var falloff: float = clampf(
				1.0 - Vector2(x + 0.5, y + 0.5).distance_to(center) / max_distance, 0.0, 1.0
			)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, falloff * falloff))
	return ImageTexture.create_from_image(image)


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
	_resize_shadow(count)


func _resize_shadow(count: int) -> void:
	_shadow.visible = count > 0
	if count <= 0:
		return
	# crowd_layout places the front rank at local z = 0 and rows behind it
	# at positive z, so the crowd spans x in [-half_width, half_width] and
	# z in [0, depth].
	var half_width: float = 0.4
	var depth: float = 0.4
	for pos in RunRules.crowd_layout(count):
		half_width = maxf(half_width, absf(pos.x))
		depth = maxf(depth, pos.z)
	# Quad lies in its local XY; after the -90 deg X tilt local Y maps to
	# world Z (track depth). Recentre it over the crowd's actual span.
	_shadow.position.z = depth * 0.5
	_shadow.scale = Vector3(half_width * 2.0 + SHADOW_MARGIN, depth + SHADOW_MARGIN, 1.0)


func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node as MeshInstance3D
	for child in node.get_children():
		var result := _find_mesh_instance(child)
		if result != null:
			return result
	return null
