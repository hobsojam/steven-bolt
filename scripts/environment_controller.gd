extends Node3D

# Turns environment_zones.gd's pure data into an actual sky change and
# roadside scenery. Placeholder geometry only (simple PrimitiveMesh shapes,
# no .glb) - see ART_SPEC.md's roadside-props addendum for the real-art
# follow-up; this ships the mechanic without waiting on that.

const EnvironmentZones := preload("res://scripts/environment_zones.gd")

const PROP_SIDE_OFFSET := 5.0

var _zones: Array[Dictionary] = EnvironmentZones.zones()
var _current_zone: Dictionary = {}

@onready var _run = get_node("..")
@onready var _world_environment: WorldEnvironment = get_node("../WorldEnvironment")
@onready var _sky_material: ProceduralSkyMaterial = (
	_world_environment.environment.sky.sky_material
)


func _ready() -> void:
	_spawn_props()
	_apply_zone(EnvironmentZones.zone_for_distance(0.0, _zones))


func _process(_delta: float) -> void:
	var zone: Dictionary = EnvironmentZones.zone_for_distance(_run.distance_traveled, _zones)
	if zone != _current_zone:
		_apply_zone(zone)


func _apply_zone(zone: Dictionary) -> void:
	_current_zone = zone
	_sky_material.sky_top_color = zone["sky_top"].srgb_to_linear()
	_sky_material.sky_horizon_color = zone["sky_horizon"].srgb_to_linear()
	_world_environment.environment.ambient_light_energy = zone["ambient_energy"]


func _spawn_props() -> void:
	for zone in _zones:
		var positions: Array[Vector3] = EnvironmentZones.prop_positions_for_zone(
			zone, PROP_SIDE_OFFSET
		)
		match zone["prop_type"]:
			"tree":
				_add_multimesh(_trunk_mesh(), Color("6b4a2f"), positions, Vector3(0.0, 0.35, 0.0))
				_add_multimesh(_canopy_mesh(), Color("2f9e52"), positions, Vector3(0.0, 1.25, 0.0))
			"rock":
				_add_multimesh(_rock_mesh(), Color("8d8d8d"), positions, Vector3(0.0, 0.25, 0.0))
			"banner":
				_add_multimesh(_pole_mesh(), Color("6b4a2f"), positions, Vector3(0.0, 0.9, 0.0))
				_add_multimesh(_flag_mesh(), Color("ffd34e"), positions, Vector3(0.22, 1.5, 0.0))


func _add_multimesh(
	mesh: Mesh, color: Color, positions: Array[Vector3], local_offset: Vector3
) -> void:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = positions.size()
	for i in positions.size():
		var transform := Transform3D(Basis.IDENTITY, positions[i] + local_offset)
		multimesh.set_instance_transform(i, transform)
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color.srgb_to_linear()
	instance.material_override = material
	add_child(instance)


func _trunk_mesh() -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.08
	mesh.bottom_radius = 0.1
	mesh.height = 0.7
	mesh.radial_segments = 6
	return mesh


func _canopy_mesh() -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = 0.55
	mesh.height = 1.1
	mesh.radial_segments = 6
	return mesh


func _rock_mesh() -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = 0.4
	mesh.height = 0.5
	mesh.radial_segments = 6
	mesh.rings = 4
	return mesh


func _pole_mesh() -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.05
	mesh.bottom_radius = 0.05
	mesh.height = 1.8
	mesh.radial_segments = 6
	return mesh


func _flag_mesh() -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.5, 0.35, 0.02)
	return mesh
