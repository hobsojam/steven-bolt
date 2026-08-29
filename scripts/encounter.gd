extends RefCounted

# Base lifecycle for a spawned encounter.
#
# gate_row / toll_wall / pickup entries resolve instantly the frame the
# crowd crosses them (see run_controller.gd's _resolve_entry). An
# encounter is the other kind of level entry: it exists and is simulated
# over many frames - spawned and visible from level start (like gates
# seen from a distance via the chase camera's lookahead, not a pop-in),
# then updated every frame while the run is RUNNING until it finishes.
#
# run_controller.gd owns a list of active encounters and knows only these
# four methods - no per-type state or update branches live in the
# controller anymore:
#
#   _init(entry)        Build the pure runtime state from the level entry.
#                       Runs with no scene tree, so update() / is_complete()
#                       can be driven straight from a headless test.
#
#   spawn(parent)       Build the visual and add it under `parent`. Called
#                       once, at level load.
#
#   update(delta, ctx)  Advance one frame. `ctx` is a read-only snapshot
#                       of the run this frame:
#                         { crowd_count, current_lane,
#                           distance_traveled, crowd_z }
#                       Returns a result dictionary:
#                         { feedback: Array of [kind: StringName, amount],
#                           breach_cost: int }
#                       run_controller emits each feedback event in order,
#                       then (if breach_cost > 0) applies it to the crowd
#                       and resolves the failure / damage feedback and the
#                       GAME_OVER transition itself - so the same crowd
#                       math and ordering apply no matter which encounter
#                       produced the cost. Use empty_result() for a frame
#                       with nothing to report.
#
#   is_complete()       True once the encounter is finished. Checked every
#                       frame right after update(); when it first turns
#                       true the controller calls cleanup() and drops the
#                       encounter from its active list.
#
#   cleanup()           Free the visual. The default implementation is
#                       enough for every current encounter and is safe to
#                       call more than once.
#
# Adding a new encounter type:
#   1. Add a runtime class under scripts/ holding the pure resolution
#      math (see enemy_wave_runtime.gd / rival_crowd_runtime.gd), kept
#      free of the scene tree so tests/run_tests.gd can exercise it
#      headlessly.
#   2. Add a subclass of this file that owns that runtime plus a visual
#      and maps them onto the four methods above.
#   3. Register the new "kind" string in encounter_factory.gd.
#   4. Add the entry to level_one_definition.gd as plain data.
#   run_controller.gd does not change.

var _entry: Dictionary = {}
var _visual: Node3D = null


func _init(entry: Dictionary) -> void:
	_entry = entry


func spawn(_parent: Node3D) -> void:
	pass


func update(_delta: float, _ctx: Dictionary) -> Dictionary:
	return empty_result()


func is_complete() -> bool:
	return true


func cleanup() -> void:
	if _visual != null and is_instance_valid(_visual):
		_visual.queue_free()
	_visual = null


static func empty_result() -> Dictionary:
	return {"feedback": [], "breach_cost": 0}
