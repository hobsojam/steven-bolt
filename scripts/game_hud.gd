extends CanvasLayer

@onready var _crowd = get_node("../CrowdController")
@onready var _run = get_node("..")
@onready var _crowd_label: Label = $CrowdCountPanel/Margin/CrowdCountLabel
@onready var _end_run_panel: PanelContainer = $EndRunPanel
@onready var _end_run_label: Label = $EndRunPanel/Margin/EndRunLabel
@onready var _start_panel: PanelContainer = $StartPanel
@onready var _screen_tint: ColorRect = $ScreenTint


func _process(_delta: float) -> void:
	_crowd_label.text = "CROWD  %d" % _crowd.crowd_count
	_start_panel.visible = _run.is_start()
	if _run.is_game_over():
		_end_run_label.text = "GAME OVER\n\nPress Enter to Restart"
		_end_run_panel.visible = true
	elif _run.is_finished():
		_end_run_label.text = (
			"LEVEL COMPLETE!\n\nCROWD  %d\nPress Enter to Restart" % _crowd.crowd_count
		)
		_end_run_panel.visible = true
	else:
		_end_run_panel.visible = false
	_screen_tint.visible = _start_panel.visible or _end_run_panel.visible
