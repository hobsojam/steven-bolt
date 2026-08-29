extends RefCounted

# Cheap, self-freeing combat VFX helpers. Deliberately built from code
# (CPUParticles3D + unshaded additive quads) rather than authored particle
# scenes or the renderer's glow pass: the project targets the GL
# Compatibility renderer, where screen-space glow/SSAO are unavailable, so
# "it glows" has to come from additive blending on a bright emissive
# material instead.
#
# Every spawned node parents itself under the caller and queues itself
# free when its animation finishes, so callers fire-and-forget.

const KILL_COLOR := Color("fff2a0")  # warm white-yellow, the reference's "shred" spark
const MUZZLE_COLOR := Color("fff3b0")


static func spawn_burst(
	parent: Node3D, local_position: Vector3, color: Color, amount: int, speed: float
) -> void:
	var burst := CPUParticles3D.new()
	burst.position = local_position
	burst.emitting = false
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.amount = maxi(amount, 1)
	burst.lifetime = 0.38
	burst.direction = Vector3.UP
	burst.spread = 180.0
	burst.initial_velocity_min = speed * 0.35
	burst.initial_velocity_max = speed
	burst.gravity = Vector3(0.0, -7.0, 0.0)
	burst.scale_amount_min = 0.12
	burst.scale_amount_max = 0.34
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.5, 0.5)
	mesh.material = _spark_material(color)
	burst.mesh = mesh
	parent.add_child(burst)
	burst.emitting = true
	burst.finished.connect(burst.queue_free)


static func spawn_flash(
	parent: Node3D, local_position: Vector3, color: Color, size: float, lifetime: float
) -> void:
	var flash := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(size, size)
	flash.mesh = mesh
	var material := _spark_material(color)
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	flash.material_override = material
	flash.position = local_position
	flash.scale = Vector3.ONE * 0.4
	parent.add_child(flash)
	var tween := flash.create_tween()
	tween.tween_property(flash, "scale", Vector3.ONE * 1.35, lifetime)
	tween.parallel().tween_property(material, "albedo_color:a", 0.0, lifetime)
	tween.tween_callback(flash.queue_free)


static func _spark_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# Hex colours are authored sRGB; albedo is a linear-space property
	# (same convention as enemy_wave_visual.gd / ART_SPEC.md).
	material.albedo_color = color.srgb_to_linear()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.billboard_keep_scale = true
	return material
