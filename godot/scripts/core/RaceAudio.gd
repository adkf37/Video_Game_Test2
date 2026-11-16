extends Node
## Layered score, varied event sounds, dog voices, speed-reactive sled Foley and positional rival audio.
const SCORES := [
	[preload("res://assets/audio/music_alpine.ogg"), preload("res://assets/audio/music_alpine_drive.ogg")],
	[preload("res://assets/audio/music_jungle.ogg"), preload("res://assets/audio/music_jungle_drive.ogg")],
	[preload("res://assets/audio/music_candy.ogg"), preload("res://assets/audio/music_candy_drive.ogg")],
	[preload("res://assets/audio/music_city.ogg"), preload("res://assets/audio/music_city_drive.ogg")]]
const AMBIENCE := [preload("res://assets/audio/ambience_alpine.ogg"), preload("res://assets/audio/ambience_jungle.ogg"),
	preload("res://assets/audio/ambience_candy.ogg"), preload("res://assets/audio/ambience_city.ogg")]
const SOUNDS := {
	"pickup": [preload("res://assets/audio/pickup_0.ogg"), preload("res://assets/audio/pickup_1.ogg"), preload("res://assets/audio/pickup_2.ogg")],
	"throw": [preload("res://assets/audio/throw_0.ogg"), preload("res://assets/audio/throw_1.ogg"), preload("res://assets/audio/throw_2.ogg")],
	"boost": [preload("res://assets/audio/boost_0.ogg"), preload("res://assets/audio/boost_1.ogg")],
	"crash": [preload("res://assets/audio/crash_0.ogg"), preload("res://assets/audio/crash_1.ogg"),
		preload("res://assets/audio/crash_2.ogg"), preload("res://assets/audio/crash_3.ogg")],
	"coconut": [preload("res://assets/audio/coconut_0.ogg"), preload("res://assets/audio/coconut_1.ogg"), preload("res://assets/audio/coconut_2.ogg")],
	"speed": [preload("res://assets/audio/speed.ogg")], "warning": [preload("res://assets/audio/warning.ogg")],
	"countdown": [preload("res://assets/audio/countdown.ogg")], "go": [preload("res://assets/audio/go.ogg")],
	"lap": [preload("res://assets/audio/lap.ogg")], "finish": [preload("res://assets/audio/finish.ogg")],
	"final_lap": [preload("res://assets/audio/final_lap.ogg")], "overtake": [preload("res://assets/audio/overtake.ogg")]}
const VARIED := ["pickup", "throw", "boost", "crash", "coconut"]
const BARKS := [preload("res://assets/audio/dog_bark_0.ogg"), preload("res://assets/audio/dog_bark_1.ogg"),
	preload("res://assets/audio/dog_bark_2.ogg"), preload("res://assets/audio/dog_bark_3.ogg"),
	preload("res://assets/audio/dog_bark_4.ogg"), preload("res://assets/audio/dog_bark_5.ogg")]
const HOWL := preload("res://assets/audio/dog_howl.ogg")
const PANT := preload("res://assets/audio/dog_pant.ogg")
const GLIDE := preload("res://assets/audio/runner_glide.ogg")
const SCRAPE := preload("res://assets/audio/runner_scrape.ogg")
const ROUGH := preload("res://assets/audio/runner_rough.ogg")
const DOG_REACTIONS := {"go": "chorus", "boost": "yip", "pickup": "yip", "crash": "bark", "coconut": "yelp",
	"final_lap": "howl", "finish": "chorus_howl", "overtake": "yip"}
const SPEED_OF_SOUND := 343.0
var music := AudioStreamPlayer.new()
var layers := AudioStreamSynchronized.new()
var ambience := AudioStreamPlayer.new()
var listener := AudioListener3D.new()
var voices: Array[AudioStreamPlayer] = []
var dog_voices: Array[AudioStreamPlayer] = []
var spatial_voices: Array[AudioStreamPlayer3D] = []
var streams: Dictionary = {}
var barks := AudioStreamRandomizer.new()
var cooldowns: Dictionary = {}
var scheduled: Array[Dictionary] = []
var foley: Array[Dictionary] = []
var rival_foley: Dictionary = {}
var speed_armed := [true, true]
var final_called := [false, false]
var last_places := [0, 0]
var place_timer := 0.0
var enabled := DisplayServer.get_name() != "headless"
var duck := 0.0
var intensity := 0.2
var effect_count := 0
@onready var manager: Node = get_parent().get_node("RaceManager")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if AudioServer.get_bus_index("RaceMix") < 0:
		AudioServer.add_bus()
		var bus := AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus, "RaceMix")
		AudioMix.configure_master(bus)
	if GameState.race_mode == 1:
		_add_player_bus("RaceP1", -0.55)
		_add_player_bus("RaceP2", 0.55)
	for kind: String in SOUNDS:
		var varied: bool = kind in VARIED
		streams[kind] = _randomizer(SOUNDS[kind], AudioMix.VARIANT_PITCH_SPREAD if varied else 1.0, AudioMix.VARIANT_VOLUME_SPREAD_DB if varied else 0.0)
	barks = _randomizer(BARKS, AudioMix.DOG_BARK_SPREAD.x, AudioMix.DOG_BARK_SPREAD.y)
	add_child(music)
	music.bus = "RaceMix"
	layers.stream_count = 2
	for i in range(2):
		SCORES[GameState.course][i].loop = true
		layers.set_sync_stream(i, SCORES[GameState.course][i])
	music.stream = layers
	music.volume_db = -60
	add_child(ambience)
	ambience.bus = "RaceMix"
	ambience.stream = _loop(AMBIENCE[GameState.course])
	ambience.volume_db = -80
	for i in range(8):
		voices.append(_voice(AudioStreamPlayer.new()))
	for i in range(6):
		dog_voices.append(_voice(AudioStreamPlayer.new()))
		var spatial := AudioStreamPlayer3D.new()
		add_child(spatial)
		spatial.bus = "RaceMix"
		spatial.unit_size = AudioMix.SPATIAL_UNIT_SIZE
		spatial.max_distance = AudioMix.SPATIAL_MAX_DISTANCE
		spatial_voices.append(spatial)
	add_child(listener)
	listener.make_current()
	if enabled:
		music.play()
		ambience.play()

func _voice(voice: AudioStreamPlayer) -> AudioStreamPlayer:
	add_child(voice)
	voice.bus = "RaceMix"
	return voice

func _add_player_bus(bus_name: String, pan: float) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var bus := AudioServer.bus_count - 1
	AudioServer.set_bus_name(bus, bus_name)
	AudioServer.set_bus_send(bus, "RaceMix")
	var panner := AudioEffectPanner.new()
	panner.pan = pan
	AudioServer.add_bus_effect(bus, panner)

# Each human's own sounds stay on their half of the stereo field in two-player races.
func _bus_for(player_index: int) -> String:
	var bus_name := "RaceP%d" % (player_index + 1)
	return bus_name if GameState.race_mode == 1 and AudioServer.get_bus_index(bus_name) >= 0 else "RaceMix"

func _randomizer(list: Array, pitch: float, volume: float) -> AudioStreamRandomizer:
	var randomizer := AudioStreamRandomizer.new()
	for stream: AudioStream in list:
		randomizer.add_stream(-1, stream)
	randomizer.random_pitch = pitch
	randomizer.random_volume_offset_db = volume
	return randomizer

func _loop(stream: AudioStreamOggVorbis) -> AudioStreamOggVorbis:
	stream.loop = true
	return stream

func _process(delta: float) -> void:
	for key in cooldowns.keys():
		cooldowns[key] -= delta
		if cooldowns[key] <= 0:
			cooldowns.erase(key)
	duck = maxf(0, duck - delta)
	var state: int = manager.state
	var racing: bool = state == manager.RaceState.RACING
	var paused := get_tree().paused
	if state in [manager.RaceState.MENU, manager.RaceState.COUNTDOWN]:
		final_called = [false, false]
		last_places = [0, 0]
		if state == manager.RaceState.MENU:
			scheduled.clear()
	_run_schedule(delta, paused)
	_update_mix(delta, state, paused)
	_update_listener()
	_update_foley(delta, state, paused)
	if GameState.muted or paused:
		for voice in voices + dog_voices:
			voice.stop()
		for spatial in spatial_voices:
			spatial.stop()
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
	place_timer -= delta
	if place_timer <= 0:
		place_timer = 0.4
		_check_places()

func _lead_speed() -> float:
	var fastest := 0.0
	for player in manager.players:
		fastest = maxf(fastest, clampf(absf(player.current_speed) / SledTuning.BOOST_SPEED, 0, 1))
	return fastest

func _update_mix(delta: float, state: int, paused: bool) -> void:
	var racing: bool = state == manager.RaceState.RACING
	var final_lap: bool = racing and (final_called[0] or final_called[1])
	var target := AudioMix.INTENSITY_MENU
	if state == manager.RaceState.COUNTDOWN:
		target = AudioMix.INTENSITY_COUNTDOWN
	elif state in [manager.RaceState.RACING, manager.RaceState.FINISHED]:
		target = AudioMix.INTENSITY_FINAL_LAP if final_lap else AudioMix.INTENSITY_RACING + AudioMix.INTENSITY_SPEED_BONUS * _lead_speed()
	intensity = move_toward(intensity, target, delta * AudioMix.INTENSITY_PER_SEC)
	layers.set_sync_stream_volume(0, AudioMix.level("music", 0.0))
	layers.set_sync_stream_volume(1, AudioMix.level("drums", lerpf(AudioMix.DRUMS_QUIET_DB, AudioMix.DRUMS_FULL_DB, intensity)))
	var target_db := (AudioMix.MUSIC_RACING_DB if racing else AudioMix.MUSIC_MENU_DB) + (AudioMix.MUSIC_DUCK_DB if duck > 0 else 0.0) \
		+ (AudioMix.MUSIC_PAUSED_DB if paused else 0.0) + (AudioMix.MUSIC_FINAL_LAP_DB if final_lap else 0.0)
	music.volume_db = AudioMix.SILENT if GameState.muted else move_toward(music.volume_db, target_db, delta * AudioMix.MUSIC_FADE_DB_PER_SEC)
	var bed_db := (AudioMix.AMBIENCE_RACING_DB if racing else AudioMix.AMBIENCE_MENU_DB) + (AudioMix.AMBIENCE_PAUSED_DB if paused else 0.0)
	ambience.volume_db = AudioMix.SILENT if GameState.muted else move_toward(ambience.volume_db, AudioMix.level("ambience", bed_db), delta * AudioMix.AMBIENCE_FADE_DB_PER_SEC)

func _update_listener() -> void:
	var humans: Array = manager.players
	if humans.is_empty():
		return
	var camera := get_viewport().get_camera_3d()
	if humans.size() == 1 and camera:
		listener.global_transform = camera.global_transform
		return
	var center := Vector3.ZERO
	var heading := Vector3.ZERO
	for player in humans:
		center += player.global_position
		heading += -player.global_basis.z
	center /= humans.size()
	heading.y = 0
	var facing := heading.normalized() if heading.length() > 0.1 else Vector3.FORWARD
	listener.global_transform = Transform3D(Basis.looking_at(facing, Vector3.UP), center + Vector3.UP * 2.0)

func _fade(node: Node, target: float, delta: float, snap: bool) -> void:
	node.volume_db = target if snap else move_toward(node.volume_db, target, delta * AudioMix.FOLEY_FADE_DB_PER_SEC)

func _update_foley(delta: float, state: int, paused: bool) -> void:
	var snap := paused or GameState.muted
	var moving: bool = state in [manager.RaceState.RACING, manager.RaceState.FINISHED] and not GameState.muted
	var panting: bool = state in [manager.RaceState.COUNTDOWN, manager.RaceState.RACING, manager.RaceState.FINISHED] and not GameState.muted
	for i in range(manager.players.size()):
		if foley.size() <= i:
			foley.append(_make_foley(i))
		var player = manager.players[i]
		var parts: Dictionary = foley[i]
		var norm := clampf(absf(player.current_speed) / SledTuning.BOOST_SPEED, 0, 1)
		var drive := sqrt(norm)
		var glide := AudioMix.SILENT
		var scrape := AudioMix.SILENT
		var rough := AudioMix.SILENT
		var pant := AudioMix.SILENT
		var breed: int = GameState.breed if i == 0 else GameState.breed2
		if moving and not paused and norm > 0.02:
			glide = lerpf(AudioMix.GLIDE_QUIET_DB, AudioMix.GLIDE_LOUD_DB, drive) - (AudioMix.GLIDE_OFFROAD_CUT_DB if player.offroad else 0.0)
			scrape = lerpf(AudioMix.SCRAPE_QUIET_DB, AudioMix.SCRAPE_LOUD_DB, drive) if player.drifting else AudioMix.SILENT
			rough = lerpf(AudioMix.ROUGH_QUIET_DB, AudioMix.ROUGH_LOUD_DB, drive) if player.offroad else AudioMix.SILENT
		if panting and not paused:
			pant = AudioMix.PANT_BASE_DB + AudioMix.PANT_SPEED_RANGE_DB * norm + linear_to_db(float(RaceCatalog.TEAM_COUNTS[breed]) / 4.0) * AudioMix.PANT_TEAM_SIZE_DB
		_fade(parts.glide, AudioMix.level("foley", glide), delta, snap)
		_fade(parts.scrape, AudioMix.level("foley", scrape), delta, snap)
		_fade(parts.rough, AudioMix.level("foley", rough), delta, snap)
		_fade(parts.pant, AudioMix.level("foley", pant), delta, snap)
		parts.glide.pitch_scale = AudioMix.GLIDE_PITCH.x + AudioMix.GLIDE_PITCH.y * norm
		parts.scrape.pitch_scale = AudioMix.SCRAPE_PITCH.x + AudioMix.SCRAPE_PITCH.y * norm
		parts.rough.pitch_scale = AudioMix.ROUGH_PITCH.x + AudioMix.ROUGH_PITCH.y * norm
		parts.pant.pitch_scale = sqrt(AudioMix.BREED_PITCH[breed]) * (AudioMix.PANT_PITCH.x + AudioMix.PANT_PITCH.y * norm)
	for rival in manager.rivals:
		var id: int = rival.get_instance_id()
		if not rival_foley.has(id):
			rival_foley[id] = _make_rival_foley(rival)
		var entry: Dictionary = rival_foley[id]
		var norm := clampf(absf(rival.current_speed) / SledTuning.BOOST_SPEED, 0, 1)
		var target := lerpf(AudioMix.RIVAL_GLIDE_QUIET_DB, AudioMix.RIVAL_GLIDE_LOUD_DB, sqrt(norm)) if moving and not paused and norm > 0.02 else AudioMix.SILENT
		_fade(entry.player, AudioMix.level("rivals", target), delta, snap)
		entry.player.pitch_scale = (AudioMix.RIVAL_PITCH.x + AudioMix.RIVAL_PITCH.y * norm) * _doppler(rival)
		if rival.boosting and not entry.boosting:
			event_at("boost", rival.global_position)
		entry.boosting = rival.boosting

# Pitch shift from the rival's speed toward or away from the listener.
func _doppler(source: Node3D) -> float:
	var offset: Vector3 = listener.global_position - source.global_position
	if offset.length() < 0.5:
		return 1.0
	var toward := offset.normalized()
	var source_speed: float = source.get_real_velocity().dot(toward)
	var listener_speed := 0.0
	if not manager.players.is_empty():
		listener_speed = manager.players[0].get_real_velocity().dot(-toward)
	return clampf((SPEED_OF_SOUND + listener_speed) / (SPEED_OF_SOUND - source_speed), AudioMix.DOPPLER_LIMITS.x, AudioMix.DOPPLER_LIMITS.y)

func _make_foley(index: int) -> Dictionary:
	var parts := {}
	for entry: Array in [["glide", GLIDE], ["scrape", SCRAPE], ["rough", ROUGH], ["pant", PANT]]:
		var player := AudioStreamPlayer.new()
		add_child(player)
		player.bus = _bus_for(index)
		player.stream = _loop(entry[1])
		player.volume_db = -80
		if enabled:
			player.play()
		parts[entry[0]] = player
	return parts

func _make_rival_foley(rival: Node3D) -> Dictionary:
	var player := AudioStreamPlayer3D.new()
	rival.add_child(player)
	player.bus = "RaceMix"
	player.stream = _loop(GLIDE)
	player.volume_db = -80
	player.unit_size = AudioMix.RIVAL_UNIT_SIZE
	player.max_distance = AudioMix.RIVAL_MAX_DISTANCE
	if enabled:
		player.play()
	return {"player": player, "boosting": false}

func _check_places() -> void:
	if manager.elapsed_time < 5.0:
		return
	for i in range(manager.players.size()):
		var place: int = manager.player_position(i)
		if last_places[i] > 0 and place < last_places[i]:
			event("overtake", i)
		last_places[i] = place

func _run_schedule(delta: float, paused: bool) -> void:
	if paused:
		return
	for i in range(scheduled.size() - 1, -1, -1):
		scheduled[i].delay -= delta
		if scheduled[i].delay <= 0:
			_play_dog(scheduled[i])
			scheduled.remove_at(i)

func _queue_dog(howl: bool, player_index: int, delay: float, pitch: float, volume: float) -> void:
	scheduled.append({"howl": howl, "player": player_index, "delay": delay, "pitch": pitch, "volume": volume})

func _play_dog(request: Dictionary) -> void:
	if not enabled or GameState.muted:
		return
	var voice := _free_voice(dog_voices) as AudioStreamPlayer
	voice.bus = _bus_for(request.player)
	voice.stream = HOWL if request.howl else barks
	voice.pitch_scale = request.pitch
	voice.volume_db = AudioMix.level("dogs", request.volume)
	voice.play()

# Bigger teams answer with a louder chorus, and breeds differ in pitch.
func _dog_reaction(kind: String, player_index: int) -> void:
	var reaction: String = DOG_REACTIONS.get(kind, "")
	var key := "dog" + str(player_index) + reaction
	if reaction == "" or cooldowns.has(key):
		return
	cooldowns[key] = 4.0 if reaction.contains("howl") else 1.5
	var breed: int = GameState.breed if player_index == 0 else GameState.breed2
	var pitch: float = AudioMix.BREED_PITCH[breed]
	var count := clampi(ceili(RaceCatalog.TEAM_COUNTS[breed] / 4.0), 1, 3)
	if reaction.begins_with("chorus"):
		for i in range(count):
			_queue_dog(false, player_index, 0.04 + i * 0.09 + randf() * 0.05, pitch * randf_range(0.93, 1.07), AudioMix.DOG_CHORUS_DB + AudioMix.DOG_CHORUS_STEP_DB * i)
	if reaction.ends_with("howl"):
		_queue_dog(true, player_index, 0.25 if reaction == "howl" else 0.6, pitch, AudioMix.DOG_HOWL_DB)
	match reaction:
		"yip":
			_queue_dog(false, player_index, 0.0, pitch * 1.35, AudioMix.DOG_YIP_DB)
		"bark":
			_queue_dog(false, player_index, 0.05, pitch, AudioMix.DOG_BARK_DB)
		"yelp":
			_queue_dog(false, player_index, 0.0, pitch * 1.6, AudioMix.DOG_YELP_DB)

func _free_voice(pool: Array) -> Node:
	for voice: Node in pool:
		if not voice.playing:
			return voice
	return pool[0]

func event(kind: String, player_index: int = 0) -> void:
	if GameState.muted or get_tree().paused or not SOUNDS.has(kind):
		return
	var key := kind + str(player_index)
	if cooldowns.has(key):
		return
	cooldowns[key] = _cooldown(kind)
	effect_count += 1
	duck = 0.4
	_dog_reaction(kind, player_index)
	if not enabled:
		return
	var selected := _free_voice(voices) as AudioStreamPlayer
	selected.bus = _bus_for(player_index)
	selected.stream = streams[kind]
	selected.volume_db = AudioMix.level("sfx", AudioMix.event_db(kind))
	selected.pitch_scale = AudioMix.PLAYER_TWO_PITCH if player_index == 1 else 1.0
	selected.play()

# Sounds from rivals and other sleds, heard with distance attenuation.
func event_at(kind: String, position: Vector3) -> void:
	if GameState.muted or get_tree().paused or not SOUNDS.has(kind):
		return
	var key := kind + "_at"
	if cooldowns.has(key):
		return
	cooldowns[key] = _cooldown(kind)
	effect_count += 1
	if not enabled:
		return
	var selected := _free_voice(spatial_voices) as AudioStreamPlayer3D
	selected.global_position = position
	selected.stream = streams[kind]
	selected.volume_db = AudioMix.level("sfx", AudioMix.SPATIAL_SFX_DB)
	selected.play()

func _cooldown(kind: String) -> float:
	if kind in ["crash", "coconut"]:
		return 0.24
	if kind == "overtake":
		return 3.0
	return 1.5 if kind in ["boost", "speed", "warning"] else 0.12

func cue(frequency: float, _duration: float) -> void:
	if frequency < 800:
		event("countdown")
	elif frequency < 1000:
		event("go")
	else:
		_lap_cue()

func _lap_cue() -> void:
	for i in range(mini(manager.player_trackers.size(), 2)):
		if manager.player_trackers[i].current_lap == manager.max_laps - 1 and not final_called[i]:
			final_called[i] = true
			event("final_lap", i)
			return
	event("lap")

func _exit_tree() -> void:
	music.stop()
	music.stream = null
	ambience.stop()
	ambience.stream = null
	for voice in voices + dog_voices:
		voice.stop()
		voice.stream = null
	for spatial in spatial_voices:
		spatial.stop()
		spatial.stream = null
	for parts in foley:
		for part: AudioStreamPlayer in parts.values():
			part.stop()
			part.stream = null
	for entry: Dictionary in rival_foley.values():
		if is_instance_valid(entry.player):
			entry.player.stop()
			entry.player.stream = null
	for bus_name in ["RaceP1", "RaceP2", "RaceMix"]:
		var bus := AudioServer.get_bus_index(bus_name)
		if bus >= 0:
			AudioServer.remove_bus(bus)
