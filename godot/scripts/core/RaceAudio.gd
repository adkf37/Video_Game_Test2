extends Node
## Original melodic score plus pooled event sounds. No continuous runner noise.
const SCORES := [preload("res://assets/audio/music_alpine.ogg"), preload("res://assets/audio/music_jungle.ogg"),
	preload("res://assets/audio/music_candy.ogg"), preload("res://assets/audio/music_city.ogg")]
const SOUNDS := {
	"pickup": preload("res://assets/audio/pickup.ogg"), "throw": preload("res://assets/audio/throw.ogg"),
	"boost": preload("res://assets/audio/boost.ogg"), "speed": preload("res://assets/audio/speed.ogg"),
	"crash": preload("res://assets/audio/crash.ogg"), "coconut": preload("res://assets/audio/coconut.ogg"),
	"warning": preload("res://assets/audio/warning.ogg"), "countdown": preload("res://assets/audio/countdown.ogg"),
	"go": preload("res://assets/audio/go.ogg"), "lap": preload("res://assets/audio/lap.ogg"),
	"finish": preload("res://assets/audio/finish.ogg")}
var music := AudioStreamPlayer.new()
var voices: Array[AudioStreamPlayer] = []
var cooldowns: Dictionary = {}
var speed_armed := [true, true]
var enabled := DisplayServer.get_name() != "headless"
var duck := 0.0
var effect_count := 0
@onready var manager: Node = get_parent().get_node("RaceManager")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if AudioServer.get_bus_index("RaceMix") < 0:
		AudioServer.add_bus()
		var bus := AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus, "RaceMix")
		AudioServer.add_bus_effect(bus, AudioEffectLimiter.new())
	add_child(music)
	music.bus = "RaceMix"
	music.stream = SCORES[GameState.course]
	music.stream.loop = true
	music.volume_db = -60
	for i in range(8):
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		voice.bus = "RaceMix"
		voices.append(voice)
	if enabled:
		music.play()

func _process(delta: float) -> void:
	for key in cooldowns.keys():
		cooldowns[key] -= delta
		if cooldowns[key] <= 0:
			cooldowns.erase(key)
	duck = maxf(0, duck - delta)
	var racing: bool = manager.state == manager.RaceState.RACING
	var target_db := (-19.0 if racing else -24.0) - (4.0 if duck > 0 else 0.0)
	music.volume_db = -80 if GameState.muted else move_toward(music.volume_db, target_db, delta * 45)
	if GameState.muted or get_tree().paused:
		for voice in voices:
			voice.stop()
	if not racing:
		speed_armed = [true, true]
		return
	for player in manager.players:
		var index: int = player.player_index
		if player.current_speed < 15:
			speed_armed[index] = true
		elif player.current_speed > 23 and speed_armed[index]:
			speed_armed[index] = false
			if not player.boosting:
				event("speed", index)

func event(kind: String, player_index: int = 0) -> void:
	if GameState.muted or get_tree().paused or not SOUNDS.has(kind):
		return
	var key := kind + str(player_index)
	if cooldowns.has(key):
		return
	cooldowns[key] = 0.24 if kind in ["crash", "coconut"] else (1.5 if kind in ["boost", "speed", "warning"] else 0.12)
	effect_count += 1
	duck = 0.4
	if not enabled:
		return
	var selected := voices[0]
	for voice in voices:
		if not voice.playing:
			selected = voice
			break
	selected.stream = SOUNDS[kind]
	selected.volume_db = -5 if kind in ["crash", "coconut", "pickup", "boost", "finish"] else -9
	selected.pitch_scale = 1.03 if player_index == 1 else 1.0
	selected.play()

func cue(frequency: float, _duration: float) -> void:
	event("countdown" if frequency < 800 else ("go" if frequency < 1000 else "lap"))

func _exit_tree() -> void:
	music.stop()
	music.stream = null
	for voice in voices:
		voice.stop()
		voice.stream = null
	var bus := AudioServer.get_bus_index("RaceMix")
	if bus >= 0:
		AudioServer.remove_bus(bus)
