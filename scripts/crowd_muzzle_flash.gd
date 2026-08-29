extends Node3D

# Spawns brief muzzle flashes along the crowd's front edge whenever a
# volley is fired. Decoupled from the encounter visuals: it just listens
# for the run controller's &"shot" feedback (the crowd is always the
# shooter, whatever it is shooting at) and scatters the flashes across the
# crowd's actual rendered front-edge width, matching where
# enemy_wave_runtime / rival_crowd_runtime place the bullet origins.

const RunRules := preload("res://scripts/run_rules.gd")
const Vfx := preload("res://scripts/vfx.gd")

const MAX_FLASHES_PER_VOLLEY := 6
const FLASH_SIZE := 0.5
const FLASH_LIFETIME := 0.09
const FLASH_HEIGHT := 1.0
const FLASH_FORWARD := -0.35

@onready var _crowd = get_parent()
@onready var _run = get_node("../..")


func _ready() -> void:
	_run.feedback_requested.connect(_on_feedback_requested)


func _on_feedback_requested(kind: StringName, amount: int) -> void:
	if kind != &"shot":
		return
	var half_width: float = maxf(RunRules.crowd_front_edge_half_width(_crowd.crowd_count), 0.25)
	for _i in clampi(amount, 1, MAX_FLASHES_PER_VOLLEY):
		var offset_x: float = randf_range(-half_width, half_width)
		Vfx.spawn_flash(
			self,
			Vector3(offset_x, FLASH_HEIGHT, FLASH_FORWARD),
			Vfx.MUZZLE_COLOR,
			FLASH_SIZE,
			FLASH_LIFETIME
		)
