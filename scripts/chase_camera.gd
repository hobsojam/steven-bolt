extends Camera3D

# Framing: lower, closer, and a tighter FOV than a neutral chase cam, so
# the crowd fills the lower third of the frame and whatever is ahead
# (gate rows, the toll wall, an enemy mass) towers over it - the
# reference's "small squad under a huge threat" read.
const HEIGHT := 3.0
const BACK_OFFSET := 5.2
# A larger look-ahead flattens the camera's downward pitch (it aims at a
# ground-level point far beyond the crowd rather than close behind it).
# Counterintuitively, a shallower pitch is what pushes the nearby crowd
# toward the bottom of the frame instead of the middle - a steep pitch
# aims closer to directly at the crowd, centering it instead.
const LOOK_AHEAD := 26.0
const FOV := 52.0
const X_FOLLOW_SPEED := 6.0

# Transient reactions. A "punch" briefly widens the FOV and eases back
# (a speed/impact pop); "shake" adds decaying positional noise. Both are
# additive so overlapping events stack, and both are suppressed outside
# the RUNNING state.
const PUNCH_RECOVER_TIME := 0.32
const MAX_PUNCH_FOV := 7.0
const SHAKE_DECAY_PER_SECOND := 9.0
const MAX_SHAKE := 0.5

var _punch_fov: float = 0.0
var _shake: float = 0.0

@onready var _crowd: Node3D = get_node("../CrowdController")
@onready var _run: Node = get_node("..")


func _ready() -> void:
	fov = FOV
	_run.feedback_requested.connect(_on_feedback_requested)


func _process(delta: float) -> void:
	var target: Vector3 = _crowd.global_position
	position.y = target.y + HEIGHT
	position.z = target.z + BACK_OFFSET
	position.x = move_toward(position.x, target.x, X_FOLLOW_SPEED * delta)

	var live: bool = not (_run.is_start() or _run.is_game_over() or _run.is_finished())
	if not live:
		_punch_fov = 0.0
		_shake = 0.0
	_punch_fov = move_toward(_punch_fov, 0.0, MAX_PUNCH_FOV / PUNCH_RECOVER_TIME * delta)
	_shake = move_toward(_shake, 0.0, SHAKE_DECAY_PER_SECOND * delta)
	fov = FOV + _punch_fov
	if _shake > 0.001:
		position += Vector3(randf_range(-_shake, _shake), randf_range(-_shake, _shake), 0.0)

	look_at(target + Vector3(0.0, 0.0, -LOOK_AHEAD), Vector3.UP)


func _on_feedback_requested(kind: StringName, _amount: int) -> void:
	match kind:
		&"gate_gain", &"gate_loss", &"pickup_gain", &"pickup_loss":
			_add_punch(2.5)
		&"toll_pass":
			_add_punch(6.0)
		&"toll_fail":
			_add_punch(6.0)
			_add_shake(0.32)
		&"damage":
			# Fires repeatedly through a horde's contact phase; the additive
			# decaying shake turns that into a sustained rumble.
			_add_shake(0.12)
		&"failure":
			_add_shake(0.42)


func _add_punch(amount: float) -> void:
	_punch_fov = minf(_punch_fov + amount, MAX_PUNCH_FOV)


func _add_shake(amount: float) -> void:
	_shake = minf(_shake + amount, MAX_SHAKE)
