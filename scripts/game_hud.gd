extends CanvasLayer

const RunRules := preload("res://scripts/run_rules.gd")

const GAIN_COLOR := Color("42d67b")
const LOSS_COLOR := Color("eb4d5c")
const PICKUP_COLOR := Color("fff07a")
const IMPACT_COLOR := Color("ffb347")
const TOLL_COLOR := Color("65d6ff")
const COMPLETE_COLOR := Color("ffc840")
const DAMAGE_FEEDBACK_INTERVAL := 0.22

var _feedback_tween: Tween
var _flash_tween: Tween
var _count_tween: Tween
var _lane_tween: Tween
var _pending_damage: int = 0
var _damage_feedback_cooldown: float = 0.0

@onready var _crowd = get_node("../CrowdController")
@onready var _run = get_node("..")
@onready var _audio = $FeedbackAudio
@onready var _crowd_count_panel: PanelContainer = $CrowdCountPanel
@onready var _crowd_label: Label = $CrowdCountPanel/Margin/CrowdCountLabel
@onready var _lane_panel: PanelContainer = $LanePanel
@onready var _lane_label: Label = $LanePanel/Margin/LaneLabel
@onready var _feedback_label: Label = $FeedbackLabel
@onready var _event_flash: ColorRect = $EventFlash
@onready var _end_run_panel: PanelContainer = $EndRunPanel
@onready var _end_run_label: Label = $EndRunPanel/Margin/EndRunLabel
@onready var _start_panel: PanelContainer = $StartPanel
@onready var _screen_tint: ColorRect = $ScreenTint


func _ready() -> void:
	_run.feedback_requested.connect(_on_feedback_requested)
	_run.run_state_changed.connect(_on_run_state_changed)
	_crowd.lane_changed.connect(_on_lane_changed)
	_update_lane_indicator(_crowd.current_lane)
	_sync_run_panels()
	# Control sizes are reliable after their first layout pass.
	call_deferred("_set_control_pivots")


func _set_control_pivots() -> void:
	_crowd_count_panel.pivot_offset = _crowd_count_panel.size / 2.0
	_lane_panel.pivot_offset = _lane_panel.size / 2.0
	_feedback_label.pivot_offset = _feedback_label.size / 2.0


func _process(delta: float) -> void:
	_crowd_label.text = "CROWD  %d" % _crowd.crowd_count
	_damage_feedback_cooldown = maxf(_damage_feedback_cooldown - delta, 0.0)
	if _pending_damage > 0 and _damage_feedback_cooldown <= 0.0:
		_flush_damage_feedback()


func _on_run_state_changed(_state: int) -> void:
	_sync_run_panels()


func _sync_run_panels() -> void:
	_start_panel.visible = _run.is_start()
	if _run.is_game_over():
		_end_run_label.text = "RUN OVER\n\nCROWD  %d\nPress Enter to Restart" % _crowd.crowd_count
		_end_run_label.add_theme_color_override("font_color", LOSS_COLOR)
		_end_run_panel.visible = true
	elif _run.is_finished():
		_end_run_label.text = (
			"LEVEL COMPLETE!\n\nCROWD  %d\nPress Enter to Restart" % _crowd.crowd_count
		)
		_end_run_label.add_theme_color_override("font_color", COMPLETE_COLOR)
		_end_run_panel.visible = true
	else:
		_end_run_panel.visible = false
	_screen_tint.visible = _start_panel.visible or _end_run_panel.visible


func _on_lane_changed(lane: int, _direction: int) -> void:
	_update_lane_indicator(lane)
	_audio.play_feedback(&"lane")
	if _lane_tween and _lane_tween.is_valid():
		_lane_tween.kill()
	_lane_panel.scale = Vector2(1.03, 1.03)
	_lane_tween = create_tween()
	_lane_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_lane_tween.tween_property(_lane_panel, "scale", Vector2.ONE, 0.1)


func _update_lane_indicator(selected_lane: int) -> void:
	var markers: PackedStringArray = []
	for lane in RunRules.LANE_COUNT:
		markers.append("●" if lane == selected_lane else "○")
	_lane_label.text = "LANE  %s" % " ".join(markers)


func _on_feedback_requested(kind: StringName, amount: int) -> void:
	if kind == &"damage":
		_pending_damage += amount
		if _damage_feedback_cooldown <= 0.0:
			_flush_damage_feedback()
		return
	_audio.play_feedback(kind)
	match kind:
		&"gate_gain":
			_show_feedback("GATE  +%d" % amount, GAIN_COLOR, 0.2)
			_pulse_count(GAIN_COLOR)
		&"gate_loss":
			_show_feedback("GATE  -%d" % amount, LOSS_COLOR, 0.24)
			_pulse_count(LOSS_COLOR)
		&"pickup_gain":
			_show_feedback("PICKUP  +%d" % amount, PICKUP_COLOR, 0.12)
			_pulse_count(GAIN_COLOR)
		&"pickup_loss":
			_show_feedback("PICKUP  -%d" % amount, LOSS_COLOR, 0.18)
			_pulse_count(LOSS_COLOR)
		&"hit":
			_show_feedback("ENEMY DOWN", IMPACT_COLOR, 0.1)
		&"toll_pass":
			_show_feedback("TOLL CLEARED  -%d" % amount, TOLL_COLOR, 0.18)
			_pulse_count(TOLL_COLOR)
		&"toll_fail":
			_pending_damage = 0
			_show_feedback("TOLL BLOCKED", LOSS_COLOR, 0.34)
			_pulse_count(LOSS_COLOR)
		&"failure":
			_pending_damage = 0
			_show_feedback("CROWD LOST", LOSS_COLOR, 0.38)
			_pulse_count(LOSS_COLOR)
		&"complete":
			_pending_damage = 0
			_show_feedback("LEVEL COMPLETE!", COMPLETE_COLOR, 0.28)
			_pulse_count(COMPLETE_COLOR)


func _flush_damage_feedback() -> void:
	var amount: int = _pending_damage
	_pending_damage = 0
	_damage_feedback_cooldown = DAMAGE_FEEDBACK_INTERVAL
	_audio.play_feedback(&"damage")
	# A snappier full-screen hit than the other feedback flashes - a breach
	# is the one event that costs the player units without their input.
	_show_feedback("CROWD  -%d" % amount, LOSS_COLOR, 0.24)
	_pulse_count(LOSS_COLOR)


func _show_feedback(text: String, color: Color, flash_strength: float) -> void:
	if _feedback_tween and _feedback_tween.is_valid():
		_feedback_tween.kill()
	_feedback_label.text = text
	_feedback_label.visible = true
	_feedback_label.modulate = color
	_feedback_label.scale = Vector2(0.82, 0.82)
	_feedback_tween = create_tween()
	_feedback_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_feedback_tween.tween_property(_feedback_label, "scale", Vector2.ONE, 0.13)
	_feedback_tween.tween_interval(0.38)
	_feedback_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_feedback_tween.tween_property(_feedback_label, "modulate:a", 0.0, 0.22)
	_feedback_tween.tween_callback(Callable(_feedback_label, "hide"))
	_flash(color, flash_strength)


func _flash(color: Color, strength: float) -> void:
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()
	_event_flash.color = Color(color.r, color.g, color.b, strength)
	_event_flash.modulate.a = 1.0
	_event_flash.visible = true
	_flash_tween = create_tween()
	_flash_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_flash_tween.tween_property(_event_flash, "modulate:a", 0.0, 0.2)
	_flash_tween.tween_callback(Callable(_event_flash, "hide"))


func _pulse_count(color: Color) -> void:
	if _count_tween and _count_tween.is_valid():
		_count_tween.kill()
	_crowd_count_panel.scale = Vector2(1.06, 1.06)
	_crowd_count_panel.modulate = color.lightened(0.2)
	_count_tween = create_tween().set_parallel(true)
	_count_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_count_tween.tween_property(_crowd_count_panel, "scale", Vector2.ONE, 0.18)
	_count_tween.tween_property(_crowd_count_panel, "modulate", Color.WHITE, 0.18)
