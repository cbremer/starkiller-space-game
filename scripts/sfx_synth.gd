extends RefCounted
class_name SfxSynth

const SAMPLE_RATE := 22050
const MAX_AMPLITUDE := 32767.0

static var _stream_cache := {}

static func stream_for(cue_name: String) -> AudioStreamWAV:
	if _stream_cache.has(cue_name):
		return _stream_cache[cue_name]

	var stream: AudioStreamWAV = null
	match cue_name:
		"fire":
			stream = _build_sweep(1200.0, 820.0, 0.075, 0.45, 0.07)
		"bomb_drop":
			stream = _build_sweep(300.0, 170.0, 0.2, 0.55, 0.09)
		"impact":
			stream = _build_noise_burst(0.11, 0.58, 0.62)
		"enemy_destroy":
			stream = _build_sweep(760.0, 280.0, 0.18, 0.52, 0.16)
		"fuel_pickup":
			stream = _build_double_tone(430.0, 670.0, 0.14, 0.4)
		"death":
			stream = _build_sweep(250.0, 70.0, 0.42, 0.66, 0.22)
		"stage_clear":
			stream = _build_double_tone(520.0, 860.0, 0.22, 0.45)
		_:
			return null

	_stream_cache[cue_name] = stream
	return stream

static func _build_sweep(
	start_frequency: float,
	end_frequency: float,
	duration: float,
	amplitude: float,
	noise_mix: float
) -> AudioStreamWAV:
	var sample_count: int = maxi(1, int(round(SAMPLE_RATE * duration)))
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for i in range(sample_count):
		var t := float(i) / float(sample_count)
		var env := _envelope(t)
		var frequency := lerpf(start_frequency, end_frequency, t)
		var base := sin(TAU * frequency * (float(i) / float(SAMPLE_RATE)))
		var noise := rng.randf_range(-1.0, 1.0)
		var sample := (base * (1.0 - noise_mix) + noise * noise_mix) * amplitude * env
		_write_sample(data, i, sample)

	return _wav_from_pcm(data)

static func _build_noise_burst(duration: float, amplitude: float, tone_mix: float) -> AudioStreamWAV:
	var sample_count: int = maxi(1, int(round(SAMPLE_RATE * duration)))
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for i in range(sample_count):
		var t := float(i) / float(sample_count)
		var env := _envelope(t)
		var noise := rng.randf_range(-1.0, 1.0)
		var tone := sin(TAU * (440.0 + 160.0 * t) * (float(i) / float(SAMPLE_RATE)))
		var sample := (noise * (1.0 - tone_mix) + tone * tone_mix) * amplitude * env
		_write_sample(data, i, sample)

	return _wav_from_pcm(data)

static func _build_double_tone(low_frequency: float, high_frequency: float, duration: float, amplitude: float) -> AudioStreamWAV:
	var sample_count: int = maxi(1, int(round(SAMPLE_RATE * duration)))
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for i in range(sample_count):
		var t := float(i) / float(sample_count)
		var env := _envelope(t)
		var blend := smoothstep(0.0, 1.0, t)
		var low := sin(TAU * low_frequency * (float(i) / float(SAMPLE_RATE)))
		var high := sin(TAU * high_frequency * (float(i) / float(SAMPLE_RATE)))
		var sample := lerpf(low, high, blend) * amplitude * env
		_write_sample(data, i, sample)

	return _wav_from_pcm(data)

static func _wav_from_pcm(data: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.data = data
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	return stream

static func _write_sample(data: PackedByteArray, index: int, sample: float) -> void:
	var clamped := clampf(sample, -1.0, 1.0)
	var sample_int := int(round(clamped * MAX_AMPLITUDE))
	if sample_int < 0:
		sample_int += 65536
	var offset := index * 2
	data[offset] = sample_int & 0xFF
	data[offset + 1] = (sample_int >> 8) & 0xFF

static func _envelope(t: float) -> float:
	var attack := smoothstep(0.0, 0.12, t)
	var release := 1.0 - smoothstep(0.62, 1.0, t)
	return clampf(attack * release, 0.0, 1.0)
