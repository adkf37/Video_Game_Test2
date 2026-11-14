extends SceneTree
var failures := 0
var checks := 0
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + text)
	else:
		print("PASS: " + text)
func frames(n: int) -> void:
	for i in range(n):
		await physics_frame
func _run() -> void:
	var state: Node = root.get_node("GameState")
	state.practice_run = true
	state.course = 0
	state.difficulty = 1
	var tracker: Node = load("res://scripts/track/LapTracker.gd").new()
	root.add_child(tracker)
	tracker.reset(-0.04)
	tracker.sample(0.0)
	check(tracker.has_started and tracker.current_lap == 0, "first line crossing arms the race")
	for i in range(1, 101):
		tracker.sample(fmod(i * 0.01, 1.0))
	check(tracker.current_lap == 1, "a continuous circuit counts one lap")
	# Deliberately cross old checkpoint boundaries between samples.
	tracker.reset(-0.02)
	for progress in [0.01, 0.10, 0.19, 0.28, 0.37, 0.46, 0.55, 0.64, 0.73, 0.82, 0.91, 0.01]:
		tracker.sample(progress)
	check(tracker.current_lap == 1, "missing narrow marker gates never blocks a lap")
	tracker.reset(-0.02)
	for progress in [0.01, 0.98, 0.01, 0.98, 0.01]:
		tracker.sample(progress)
	check(tracker.current_lap == 0, "oscillating across start cannot farm laps")
	tracker.reset(-0.02)
	for progress in [0.01, 0.50, 0.99, 0.01]:
		tracker.sample(progress)
	check(tracker.current_lap == 0, "large teleports cannot award a lap")
	tracker.queue_free()
	var scene: Node3D = load("res://scenes/main/Main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await frames(30)
	var race: Node = scene.get_node("RaceManager")
	var sled: CharacterBody3D = scene.get_node("PlayerSled")
	var track: AlpineTrack = scene.get_node("Track")
	check(race.state == race.RaceState.MENU and sled.is_on_floor(), "basecamp loads with grounded sled")
	for breed in range(4):
		state.breed = breed
		state.sled_style = breed
		race.apply_customization()
		check(sled.visual.dogs.size() == RaceCatalog.TEAM_COUNTS[breed], "breed %d has the correct team size" % breed)
		check(sled.visual.legs.size() == RaceCatalog.TEAM_COUNTS[breed] * 4, "breed %d has animated legs" % breed)
		await frames(1)
	race.start()
	Input.action_press("move_forward")
	await frames(20)
	check(sled.get_speed_kph() < 1, "countdown locks driving")
	Input.action_release("move_forward")
	race.countdown = 0.01
	await frames(3)
	Input.action_press("move_forward")
	await frames(120)
	check(sled.get_speed_kph() > 30, "player accelerates")
	Input.action_release("move_forward")
	# Reproduce virtual keyboards that send a logical key without a scan code.
	var pause_key := InputEventKey.new()
	pause_key.keycode = KEY_ESCAPE
	pause_key.pressed = true
	Input.parse_input_event(pause_key)
	await process_frame
	await process_frame
	pause_key = pause_key.duplicate()
	pause_key.pressed = false
	Input.parse_input_event(pause_key)
	await process_frame
	var frozen := sled.position
	var frozen_time: float = race.race_time
	await frames(10)
	check(paused and sled.position.is_equal_approx(frozen) and race.race_time == frozen_time, "pause freezes physics and time")
	race.resume()
	# Force an off-track excursion at a quiet part of the course.
	var frame := track.frame_at(0.35)
	frame.origin += frame.basis.x * (track.half_width + 4)
	sled.reset_to(frame)
	race.lap_tracker.rebase(0.35)
	sled.current_speed = 25
	sled.drive_velocity = -sled.global_basis.z * 25
	Input.action_press("move_forward")
	Input.action_press("boost")
	await frames(45)
	check(sled.offroad and not sled.boosting and sled.current_speed <= 5.0, "off-track penalty rapidly slows the sled and disables boost")
	Input.action_release("boost")
	Input.action_release("move_forward")
	var before: float = track.nearest(sled.position).progress
	var before_time: float = race.race_time
	race.recover()
	check(absf(wrapf(track.nearest(sled.position).progress - before, -0.5, 0.5)) < 0.003, "recovery returns to the nearest trail point without reversing")
	check(race.race_time == before_time + 3, "manual recovery keeps its explicit time penalty")
	check(sled.impact_velocity.is_zero_approx(), "recovery clears knockback")
	race.restart()
	check(race.race_time == 0 and race.current_lap == 0 and race.finish_order.is_empty(), "restart clears race and standings")
	race.menu()
	check(not paused and race.state == race.RaceState.MENU, "basecamp return works")
	var old_path: String = state.save_path
	state.save_path = "user://tour_test_%d.cfg" % Time.get_ticks_usec()
	var config := ConfigFile.new()
	config.set_value("alpine", "best_time", 111.0)
	config.save(state.save_path)
	state.practice_run = false
	state.load_records()
	check(state.record_run(90, 28), "first course record saves")
	state.load_records()
	check(state.best_time == 90 and state.best_lap == 28, "record survives reload")
	state.set_option("course", 1)
	check(state.best_time == 0, "another track has a separate record")
	state.record_run(100, 30)
	state.set_option("difficulty", 2)
	check(state.best_time == 0, "difficulty has separate records")
	state.set_option("course", 0)
	state.set_option("difficulty", 1)
	check(state.best_time == 90, "returning to a course restores its record")
	config.load(state.save_path)
	check(config.get_value("alpine", "best_time") == 111, "legacy records are preserved")
	state.set_option("breed", 3)
	state.set_option("sled_style", 2)
	config.load(state.save_path)
	check(config.get_value("garage", "breed") == 3 and config.get_value("garage", "sled_style") == 2, "garage choices persist")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(state.save_path))
	state.save_path = old_path
	state.practice_run = true
	scene.queue_free()
	await process_frame
	print("SMOKE RESULT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
