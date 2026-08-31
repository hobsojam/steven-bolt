extends Node

# Procedural background music, same spirit as feedback_audio.gd: nothing
# is loaded from disk. Two 8-second loops (a calm bed and a busier
# "combat" layer) are synthesised into AudioStreamWAVs at startup and
# played on two always-running, phase-locked AudioStreamPlayers. Only
# their volumes move:
#   - the bed fades in when the run starts and out when it ends;
#   - the combat layer swells while shots / hits / damage are firing and
#     decays back once things are calm.
#
# Musical shape: A major, 120 BPM, a I-V-vi-IV progression (A - E - F#m -
# D), one bar each. Bass eighths, a chord pluck on beats 1 and 3, a
# sixteenth arpeggio, and a small drum kit. The combat layer adds a
# double-time arp, denser hats, and a high shimmer.

const SAMPLE_RATE := 22050
const BPM := 120.0
const BARS := 4
const BEATS_PER_BAR := 4
const LOOP_SAMPLES := int(SAMPLE_RATE * BARS * BEATS_PER_BAR * 60.0 / BPM)

const BED_VOLUME_DB := -12.0
const COMBAT_MAX_VOLUME_DB := -14.0
const SILENT_DB := -60.0
const FADE_IN := 1.3
const FADE_OUT := 0.9
# Each combat feedback event adds this to _combat_energy; it decays at
# COMBAT_DECAY_PER_SEC. Energy of COMBAT_ENERGY_FULL maps to full volume.
const COMBAT_ATTACK := 1.1
const COMBAT_DECAY_PER_SEC := 0.6
const COMBAT_ENERGY_FULL := 3.0
const COMBAT_VOLUME_SLEW_DB := 45.0

const WAVE_SINE := 0
const WAVE_BASS := 1
const WAVE_SQUARE := 2

const ENV_BASS := 0
const ENV_PLUCK := 1
const ENV_PLUCK_SHORT := 2
const ENV_PAD := 3

var _bed_player: AudioStreamPlayer
var _combat_player: AudioStreamPlayer
var _combat_energy: float = 0.0
var _running: bool = false
var _started: bool = false

@onready var _run := get_parent()


func _ready() -> void:
	_bed_player = _make_player(render_loop(false))
	_combat_player = _make_player(render_loop(true))
	add_child(_bed_player)
	add_child(_combat_player)
	_run.run_state_changed.connect(_on_run_state_changed)
	_run.feedback_requested.connect(_on_feedback_requested)


func _exit_tree() -> void:
	# Stop playback and drop the stream refs on teardown so a clean exit
	# (and CI's --quit-after 1, before playback ever starts) leaves nothing
	# behind.
	for player: AudioStreamPlayer in [_bed_player, _combat_player]:
		if is_instance_valid(player):
			player.stop()
			player.stream = null


func _process(delta: float) -> void:
	if not _running:
		return
	_combat_energy = maxf(_combat_energy - COMBAT_DECAY_PER_SEC * delta, 0.0)
	var level: float = clampf(_combat_energy / COMBAT_ENERGY_FULL, 0.0, 1.0)
	var target_db: float = (
		SILENT_DB if level < 0.02 else lerpf(SILENT_DB, COMBAT_MAX_VOLUME_DB, level)
	)
	_combat_player.volume_db = move_toward(
		_combat_player.volume_db, target_db, COMBAT_VOLUME_SLEW_DB * delta
	)


func _on_run_state_changed(_state: int) -> void:
	if _run.is_game_over() or _run.is_finished():
		_running = false
		_combat_energy = 0.0
		_fade(_bed_player, SILENT_DB, FADE_OUT)
		_fade(_combat_player, SILENT_DB, FADE_OUT)
	elif not _run.is_start():
		_running = true
		if not _started:
			# Start both loops together, once, so they stay phase-locked;
			# from here only their volumes move.
			_started = true
			_bed_player.play()
			_combat_player.play()
		_fade(_bed_player, BED_VOLUME_DB, FADE_IN)


func _on_feedback_requested(kind: StringName, _amount: int) -> void:
	if not _running:
		return
	if kind == &"shot" or kind == &"hit" or kind == &"damage":
		_combat_energy = minf(_combat_energy + COMBAT_ATTACK, COMBAT_ENERGY_FULL * 1.5)


func _make_player(samples: PackedFloat32Array) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = _to_wav(samples)
	player.volume_db = SILENT_DB
	return player


func _fade(player: AudioStreamPlayer, to_db: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(player, "volume_db", to_db, duration)


static func _to_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var count: int = samples.size()
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in count:
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = count
	stream.data = bytes
	return stream


# --- synthesis ---------------------------------------------------------

static func render_loop(combat: bool) -> PackedFloat32Array:
	var count: int = LOOP_SAMPLES
	var buffer := PackedFloat32Array()
	buffer.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 0x5713B01
	var samples_per_beat: float = float(SAMPLE_RATE) * 60.0 / BPM
	var samples_per_16th: float = samples_per_beat / 4.0
	var bar_seconds: float = BEATS_PER_BAR * samples_per_beat / float(SAMPLE_RATE)

	# semitone offsets from A4 per bar: A - E - F#m - D
	var progression := [
		{"bass": -24, "triad": [-12, -8, -5]},
		{"bass": -29, "triad": [-5, -1, 2]},
		{"bass": -27, "triad": [-3, 0, 4]},
		{"bass": -31, "triad": [-7, -3, 0]},
	]
	var arp_pattern := [0, 1, 2, 1]

	for bar in BARS:
		var chord: Dictionary = progression[bar]
		var triad: Array = chord["triad"]
		var bar_start: int = int(bar * BEATS_PER_BAR * samples_per_beat)

		# bass eighths, root, up an octave on the "&" of beats 2 and 4
		for eighth in 8:
			var start: int = bar_start + int(eighth * samples_per_beat / 2.0)
			var semitone: float = float(chord["bass"]) + (12.0 if eighth == 3 or eighth == 7 else 0.0)
			_render(buffer, start, _hz(semitone), 0.46, 0.5, WAVE_BASS, ENV_BASS)

		# chord pluck on beats 1 and 3
		for beat in [0, 2]:
			var start: int = bar_start + int(beat * samples_per_beat)
			for note in triad:
				_render(buffer, start, _hz(float(note)), 0.5, 0.075, WAVE_SINE, ENV_PLUCK)

		# sixteenth arpeggio, triad an octave up
		var arp_amp: float = 0.13 if not combat else 0.14
		for i in 16:
			var start: int = bar_start + int(i * samples_per_16th)
			var note: float = float(triad[arp_pattern[i % 4]]) + 12.0
			_render(buffer, start, _hz(note), 0.11, arp_amp, WAVE_SQUARE, ENV_PLUCK_SHORT)
			if combat:
				var mid: int = start + int(samples_per_16th / 2.0)
				_render(buffer, mid, _hz(note + 12.0), 0.06, 0.06, WAVE_SQUARE, ENV_PLUCK_SHORT)

		# drums
		_render_kick(buffer, bar_start)
		_render_kick(buffer, bar_start + int(8 * samples_per_16th))
		_render_snare(buffer, bar_start + int(4 * samples_per_16th), rng)
		_render_snare(buffer, bar_start + int(12 * samples_per_16th), rng)
		var hat_steps := [2, 6, 10, 14] if not combat else [0, 2, 4, 6, 8, 10, 12, 14]
		var hat_amp: float = 0.16 if not combat else 0.12
		for step in hat_steps:
			_render_hat(buffer, bar_start + int(step * samples_per_16th), rng, hat_amp)

		if combat:
			_render(buffer, bar_start, _hz(float(triad[2]) + 24.0), bar_seconds, 0.045, WAVE_SINE, ENV_PAD)

	# normalise to about -0.7 dBFS (wrap-around in _render keeps the loop seamless)
	var peak: float = 0.0001
	for value in buffer:
		peak = maxf(peak, absf(value))
	var gain: float = 0.92 / peak
	for i in count:
		buffer[i] = clampf(buffer[i] * gain, -1.0, 1.0)
	return buffer


static func _render(
	buffer: PackedFloat32Array,
	start: int,
	frequency: float,
	duration: float,
	amplitude: float,
	wave_kind: int,
	envelope_kind: int
) -> void:
	var n: int = buffer.size()
	var sample_count: int = int(duration * SAMPLE_RATE)
	var step: float = TAU * frequency / float(SAMPLE_RATE)
	for i in sample_count:
		var t: float = float(i) / float(SAMPLE_RATE)
		var value: float = _wave(wave_kind, step * i) * _envelope(envelope_kind, t, duration) * amplitude
		buffer[(start + i) % n] += value


static func _render_kick(buffer: PackedFloat32Array, start: int) -> void:
	var n: int = buffer.size()
	var sample_count: int = int(0.18 * SAMPLE_RATE)
	var phase: float = 0.0
	for i in sample_count:
		var t: float = float(i) / float(SAMPLE_RATE)
		var frequency: float = lerpf(130.0, 45.0, clampf(t / 0.08, 0.0, 1.0))
		phase += TAU * frequency / float(SAMPLE_RATE)
		buffer[(start + i) % n] += sin(phase) * exp(-t / 0.06) * 0.7


static func _render_snare(
	buffer: PackedFloat32Array, start: int, rng: RandomNumberGenerator
) -> void:
	var n: int = buffer.size()
	var sample_count: int = int(0.16 * SAMPLE_RATE)
	for i in sample_count:
		var t: float = float(i) / float(SAMPLE_RATE)
		var body: float = rng.randf_range(-1.0, 1.0) * 0.7 + sin(TAU * 190.0 * t) * 0.3
		buffer[(start + i) % n] += body * exp(-t / 0.055) * 0.4


static func _render_hat(
	buffer: PackedFloat32Array, start: int, rng: RandomNumberGenerator, amplitude: float
) -> void:
	var n: int = buffer.size()
	var sample_count: int = int(0.04 * SAMPLE_RATE)
	var previous: float = 0.0
	for i in sample_count:
		var t: float = float(i) / float(SAMPLE_RATE)
		var noise: float = rng.randf_range(-1.0, 1.0)
		var high_passed: float = noise - previous
		previous = noise
		buffer[(start + i) % n] += high_passed * exp(-t / 0.012) * amplitude


static func _wave(kind: int, phase: float) -> float:
	match kind:
		WAVE_BASS:
			return sin(phase) * 0.7 + sin(phase * 2.0) * 0.3
		WAVE_SQUARE:
			return sin(phase) + sin(phase * 3.0) / 3.0 + sin(phase * 5.0) / 5.0
		_:
			return sin(phase)


static func _envelope(kind: int, t: float, duration: float) -> float:
	match kind:
		ENV_BASS:
			var attack: float = minf(t / 0.008, 1.0)
			var release: float = clampf((duration - t) / 0.03, 0.0, 1.0)
			return attack * exp(-t / 0.7) * release
		ENV_PLUCK:
			return minf(t / 0.004, 1.0) * exp(-t / 0.16)
		ENV_PLUCK_SHORT:
			return minf(t / 0.003, 1.0) * exp(-t / 0.05)
		ENV_PAD:
			var attack_pad: float = minf(t / 0.12, 1.0)
			var release_pad: float = clampf((duration - t) / 0.25, 0.0, 1.0)
			return attack_pad * release_pad
		_:
			return 1.0


static func _hz(semitones_from_a4: float) -> float:
	return 440.0 * pow(2.0, semitones_from_a4 / 12.0)
