extends Node

# Short original synthesized cues; no runtime network or copyrighted samples.
const RATE := 22050
var samples: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var next_voice := 0
var enabled := true

func _ready() -> void:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		enabled = bool(config.get_value("audio", "enabled", true))
	for cue in ["web", "hit", "hurt", "success", "jump"]:
		samples[cue] = make_cue(cue)
	for i in range(4):
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -12
		add_child(voice)
		voices.append(voice)

func make_cue(kind: String) -> AudioStreamWAV:
	var duration := 0.16
	var base := 280.0
	var sweep := 0.0
	match kind:
		"web":
			base = 850
			sweep = -620
			duration = 0.18
		"hit":
			base = 140
			sweep = -75
			duration = 0.12
		"hurt":
			base = 180
			sweep = -80
			duration = 0.24
		"success":
			base = 450
			sweep = 500
			duration = 0.30
		"jump":
			base = 230
			sweep = 270
			duration = 0.18
	var bytes := PackedByteArray()
	var count := int(RATE * duration)
	bytes.resize(count * 2)
	var phase := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 919
	for i in range(count):
		var t := float(i) / float(count)
		phase += TAU * (base + sweep * t) / RATE
		var envelope := minf(1.0, t * 25.0) * (1.0 - t) * (1.0 - t)
		var noise := rng.randf_range(-1.0, 1.0) * (0.35 if kind in ["hit", "web"] else 0.05)
		bytes.encode_s16(i * 2, int(clampf((sin(phase) * 0.65 + noise) * envelope, -1.0, 1.0) * 26000))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = bytes
	return stream

func play_effect(kind: String) -> void:
	if not enabled or not samples.has(kind) or voices.is_empty():
		return
	var voice := voices[next_voice]
	next_voice = (next_voice + 1) % voices.size()
	voice.stream = samples[kind]
	voice.play()

func toggle() -> void:
	enabled = not enabled
	var config := ConfigFile.new()
	config.load("user://settings.cfg")
	config.set_value("audio", "enabled", enabled)
	config.save("user://settings.cfg")
