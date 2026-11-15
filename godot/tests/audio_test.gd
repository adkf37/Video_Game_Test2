extends SceneTree
var failures := 0
var checks := 0
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, message: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", message)
	if not ok:
		failures += 1
func frames(n: int) -> void:
	for i in range(n):
		await physics_frame
func _run() -> void:
	var settings: Node = root.get_node("GameState")
	settings.practice_run = true
	settings.muted = false
	settings.volume = 0.7
	settings.change_volume(2)
	check(is_equal_approx(settings.volume, 0.9) and AudioServer.get_bus_volume_db(0) > 0.0, "volume keys raise the shared mix")
	settings.change_volume(-20)
	check(settings.volume == 0.0 and AudioServer.is_bus_mute(0), "volume floors at silent")
	settings.change_volume(20)
	check(settings.volume == 1.0, "volume caps at full")
	settings.volume = settings.DEFAULT_VOLUME
	settings.apply_volume()
	check(is_zero_approx(AudioServer.get_bus_volume_db(0)) and not AudioServer.is_bus_mute(0), "default volume keeps the original mix level")
	for race_mode in [0, 1]:
		settings.race_mode = race_mode
		settings.course = 3 if race_mode == 1 else 0
		var scene: Node3D = load("res://scenes/main/Main.tscn").instantiate()
		root.add_child(scene)
		current_scene = scene
		await frames(8)
		var race: Node = scene.get_node("RaceManager")
		var sound: Node = scene.get_node("RaceAudio")
		for kind: String in sound.SOUNDS:
			check(sound.streams[kind] is AudioStreamRandomizer and sound.streams[kind].streams_count == sound.SOUNDS[kind].size(),
				"%s has %d sound variant(s)" % [kind, sound.SOUNDS[kind].size()])
		var sides := AudioServer.get_bus_index("RaceP1") >= 0 and AudioServer.get_bus_index("RaceP2") >= 0
		check(sides == (race_mode == 1), "two-player races give each human a stereo side")
		check(sound.foley.size() == race.players.size() and sound.rival_foley.size() == race.rivals.size(), "sled, panting and rival loops exist")
		for racer in get_nodes_in_group("racers"):
			racer.set_physics_process(false)
		var before: int = sound.effect_count
		sound.cooldowns.clear()
		sound.event_at("crash", Vector3(3, 0, 3))
		sound.event_at("crash", Vector3(3, 0, 3))
		check(sound.effect_count == before + 1, "positional sounds are throttled")
		sound.cooldowns.clear()
		sound.scheduled.clear()
		sound.event("go")
		check(sound.scheduled.size() == clampi(ceili(RaceCatalog.TEAM_COUNTS[settings.breed] / 4.0), 1, 3), "team size sets the size of the bark chorus")
		sound.cooldowns.clear()
		sound.scheduled.clear()
		sound.event("final_lap")
		check(sound.scheduled.size() == 1 and sound.scheduled[0].howl, "final lap draws a howl")
		race.state = race.RaceState.RACING
		race.player_trackers[0].current_lap = race.max_laps - 1
		sound.cooldowns.clear()
		var laps: int = sound.effect_count
		sound.cue(1100.0, 0.25)
		check(sound.final_called[0] and sound.effect_count == laps + 1 and sound.cooldowns.has("final_lap0"), "second completed lap announces the final lap")
		sound.cooldowns.clear()
		sound.cue(1100.0, 0.25)
		check(sound.cooldowns.has("lap0") and not sound.cooldowns.has("final_lap0"), "the final-lap sting plays once")
		sound.final_called = [false, false]
		sound._update_mix(1.0, race.RaceState.RACING, false)
		race.players[0].current_speed = 30.0
		sound._update_mix(4.0, race.RaceState.RACING, false)
		check(sound.intensity > 0.85, "drum layer intensifies with speed")
		sound._update_mix(10.0, race.RaceState.MENU, false)
		check(sound.intensity < 0.25, "menu keeps the score calm")
		settings.muted = true
		settings.ui_sound.play_count = 0
		var muted_events: int = sound.effect_count
		sound.event_at("crash", Vector3.ZERO)
		sound.event("crash")
		settings.play_ui("select")
		check(sound.effect_count == muted_events and settings.ui_sound.play_count == 0, "mute silences effects and menu sounds")
		settings.muted = false
		settings.play_ui("select")
		check(settings.ui_sound.play_count == 1, "menu sounds count when unmuted")
		settings.ui_sound.play_count = 0
		scene.queue_free()
		await process_frame
		check(AudioServer.get_bus_index("RaceMix") < 0 and AudioServer.get_bus_index("RaceP1") < 0, "buses are removed with the race")
	print("AUDIO RESULT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
