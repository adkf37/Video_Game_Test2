extends Node
## Quiet synthesized runner noise and cues, no external assets or downloads.
var runner := AudioStreamPlayer.new()
var chime := AudioStreamPlayer.new()
var bark := AudioStreamPlayer.new()
var was_boosting := false
var enabled := DisplayServer.get_name() != "headless"
@onready var sled: CharacterBody3D = get_parent().get_node("PlayerSled")

func _ready() -> void:
	add_child(runner)
	add_child(chime)
	add_child(bark)
	if not enabled:
		return
	var data := PackedByteArray()
	var rng := RandomNumberGenerator.new()
	rng.seed = 72
	var smooth := 0.0
	for i in range(22050):
		smooth = lerpf(smooth, rng.randf_range(-1, 1), 0.28)
		var sample := int(smooth * 8000)
		data.append(sample & 255)
		data.append((sample >> 8) & 255)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = 22050
	runner.stream = stream
	runner.volume_db = -60
	runner.play()

func _process(_delta: float) -> void:
	if not enabled:
		return
	var speed: float = sled.get_speed_kph() / 100.0
	runner.volume_db = -80.0 if GameState.muted or speed < 0.03 else lerpf(-32, -19, clampf(speed, 0, 1))
	runner.pitch_scale = 0.7 + speed * 0.5
	if sled.boosting and not was_boosting and not GameState.muted:
		bark.stream = _tone(190.0, 0.18, true)
		bark.volume_db = -18
		bark.play()
	was_boosting = sled.boosting

func _tone(frequency: float, duration: float, is_bark: bool = false) -> AudioStreamWAV:
	var data := PackedByteArray()
	for i in range(int(22050 * duration)):
		var t := float(i) / 22050
		var envelope := sin(PI * t / duration)
		var value := sin(TAU * frequency * t * (1.0 - 0.2 * t / duration))
		if is_bark:
			value = tanh(value * 3) * (0.5 + 0.5 * sin(t * 100))
		var sample := int(value * envelope * 12000)
		data.append(sample & 255)
		data.append((sample >> 8) & 255)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.data = data
	return stream

func cue(frequency: float, duration: float) -> void:
	if GameState.muted or not enabled:
		return
	chime.stream = _tone(frequency, duration)
	chime.volume_db = -20
	chime.play()

func _exit_tree() -> void:
	for player in [runner, chime, bark]:
		player.stop()
		player.stream = null
