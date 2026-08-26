extends Node

# Small procedural cues keep the feedback self-contained and cheap while still
# giving each event a distinct sound. Samples are generated once at startup;
# gameplay only swaps cached AudioStreamWAV resources into a short player pool.

const SAMPLE_RATE := 22050
const PLAYER_COUNT := 6
const BASE_AMPLITUDE := 0.24

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _last_played_ms: Dictionary = {}
var _next_player: int = 0


func _ready() -> void:
	_streams = {
		&"lane": _make_tone(520.0, 650.0, 0.06),
		&"gate_gain": _make_tone(470.0, 790.0, 0.18),
		&"gate_loss": _make_tone(330.0, 170.0, 0.22),
		&"pickup_gain": _make_tone(820.0, 1180.0, 0.12),
		&"pickup_loss": _make_tone(440.0, 260.0, 0.14),
		&"shot": _make_tone(1500.0, 920.0, 0.055),
		&"hit": _make_tone(260.0, 150.0, 0.1),
		&"damage": _make_tone(190.0, 105.0, 0.13),
		&"toll_pass": _make_tone(390.0, 820.0, 0.28),
		&"toll_fail": _make_tone(190.0, 75.0, 0.38),
		&"failure": _make_tone(250.0, 65.0, 0.5),
		&"complete": _make_tone(440.0, 980.0, 0.55),
	}
	for i in PLAYER_COUNT:
		var player := AudioStreamPlayer.new()
		player.volume_db = -8.0
		add_child(player)
		_players.append(player)


func play_feedback(kind: StringName) -> void:
	var stream: AudioStreamWAV = _streams.get(kind)
	if stream == null:
		return
	var now_ms: int = Time.get_ticks_msec()
	var cooldown_ms: int = _cooldown_ms(kind)
	if now_ms - int(_last_played_ms.get(kind, -cooldown_ms)) < cooldown_ms:
		return
	_last_played_ms[kind] = now_ms
	var player: AudioStreamPlayer = _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	player.stop()
	player.stream = stream
	player.volume_db = -12.0 if kind == &"shot" else -8.0
	player.pitch_scale = 1.0 + float((_next_player % 3) - 1) * 0.015
	player.play()


func _cooldown_ms(kind: StringName) -> int:
	if kind == &"shot":
		return 110
	if kind == &"damage":
		return 180
	return 35


func _make_tone(start_hz: float, end_hz: float, duration: float) -> AudioStreamWAV:
	var sample_count: int = int(SAMPLE_RATE * duration)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	var phase: float = 0.0
	for sample_index in sample_count:
		var progress: float = float(sample_index) / maxf(float(sample_count - 1), 1.0)
		var frequency: float = lerpf(start_hz, end_hz, progress)
		phase += TAU * frequency / SAMPLE_RATE
		var attack: float = minf(progress / 0.08, 1.0)
		var release: float = minf((1.0 - progress) / 0.28, 1.0)
		var envelope: float = attack * release
		var wave: float = sin(phase) * 0.82 + sin(phase * 2.0) * 0.18
		var value: int = int(clampf(wave * envelope * BASE_AMPLITUDE, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(sample_index * 2, value)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	return stream
