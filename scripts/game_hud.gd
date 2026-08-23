extends CanvasLayer

@onready var _crowd = get_node("../CrowdController")
@onready var _run = get_node("..")
@onready var _crowd_label: Label = $CrowdCountLabel
@onready var _game_over_label: Label = $GameOverLabel


func _process(_delta: float) -> void:
	_crowd_label.text = "Crowd: %d" % _crowd.crowd_count
	_game_over_label.visible = _run.is_game_over()
