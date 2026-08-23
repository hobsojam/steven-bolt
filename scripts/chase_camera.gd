extends Camera3D

const HEIGHT := 4.0
const BACK_OFFSET := 6.0
# A larger look-ahead flattens the camera's downward pitch (it aims at a
# ground-level point far beyond the crowd rather than close behind it).
# Counterintuitively, a shallower pitch is what pushes the nearby crowd
# toward the bottom of the frame instead of the middle - a steep pitch aims
# closer to directly at the crowd, centering it instead.
const LOOK_AHEAD := 30.0
const X_FOLLOW_SPEED := 6.0

@onready var _crowd: Node3D = get_node("../CrowdController")


func _process(delta: float) -> void:
	var target: Vector3 = _crowd.global_position
	position.y = target.y + HEIGHT
	position.z = target.z + BACK_OFFSET
	position.x = move_toward(position.x, target.x, X_FOLLOW_SPEED * delta)
	look_at(target + Vector3(0.0, 0.0, -LOOK_AHEAD), Vector3.UP)
