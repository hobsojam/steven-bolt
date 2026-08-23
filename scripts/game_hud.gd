extends CanvasLayer

@onready var _crowd = get_node("../CrowdController")
@onready var _run = get_node("..")
@onready var _crowd_label: Label = $CrowdCountLabel
@onready var _end_run_label: Label = $EndRunLabel
@onready var _start_label: Label = $StartLabel


func _process(_delta: float) -> void:
	_crowd_label.text = "Crowd: %d" % _crowd.crowd_count
	_start_label.visible = _run.is_start()
	if _run.is_game_over():
		_end_run_label.text = "GAME OVER\nPress Enter to Restart"
		_end_run_label.visible = true
	elif _run.is_finished():
		_end_run_label.text = "LEVEL COMPLETE\nCrowd: %d\nPress Enter to Restart" % _crowd.crowd_count
		_end_run_label.visible = true
	else:
		_end_run_label.visible = false
