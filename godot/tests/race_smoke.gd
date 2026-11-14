extends SceneTree
## Run with Godot --headless --path godot --script res://tests/race_smoke.gd
var failures := 0
var checks := 0
var scene: Node3D
var race: Node
var sled: CharacterBody3D
var track: AlpineTrack
var state: Node

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + description)
	else:
		print("PASS: " + description)

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame

func _run() -> void:
	state = root.get_node("GameState")
	state.practice_run = true
	scene = load("res://scenes/main/Main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	race = scene.get_node("RaceManager")
	sled = scene.get_node("PlayerSled")
	track = scene.get_node("Track")
	await frames(20)
	check(race.state == race.RaceState.MENU, "launches into basecamp")
	check(sled.is_on_floor(), "sled rests on the track collision mesh")
	check(sled.position.y > -1, "sled does not fall through the trail")
	check(track.total_length > 450, "course is a substantial closed circuit")
	var tracker: Node = race.lap_tracker
	race.start()
	check(race.state == race.RaceState.COUNTDOWN, "start enters countdown")
	Input.action_press("move_forward")
	await frames(20)
	check(sled.get_speed_kph() < 1, "countdown locks acceleration")
	check(not race.checkpoint_hit(0), "countdown blocks checkpoints")
	Input.action_release("move_forward")
	race.countdown = 0.01
	await frames(3)
	check(race.state == race.RaceState.RACING, "countdown transitions into racing")
	check(not race.checkpoint_hit(4), "skipped checkpoints are rejected")
	check(race.checkpoint_hit(0), "first forward finish-line crossing arms the lap")
	check(race.current_lap == 0, "first start-line crossing is not a completed lap")
	check(not race.checkpoint_hit(0), "repeated finish crossing cannot award a lap")
	Input.action_press("move_forward")
	await frames(120)
	Input.action_release("move_forward")
	check(sled.get_speed_kph() > 30, "physics accelerates the sled")
	check(sled.position.y > -1.5, "track supports the moving sled")
	Input.action_press("pause")
	await process_frame
	Input.action_release("pause")
	await process_frame
	check(paused and race.state == race.RaceState.PAUSED, "escape pauses the scene")
	var frozen_time: float = race.race_time
	var frozen_position := sled.position
	for i in range(10):
		await process_frame
	check(is_equal_approx(race.race_time, frozen_time), "paused race timer stays fixed")
	check(sled.position.is_equal_approx(frozen_position), "paused sled stays fixed")
	race.resume()
	check(not paused and race.state == race.RaceState.RACING, "resume restores racing")
	var before: float = race.race_time
	race.recover()
	check(is_equal_approx(race.race_time, before + 3), "recovery applies a three-second penalty")
	check(sled.velocity.is_zero_approx(), "recovery clears velocity")
	check(tracker.next_checkpoint == 1, "recovery preserves validated lap progress")
	Input.action_press("move_forward")
	Input.action_press("boost")
	await frames(80)
	Input.action_release("boost")
	Input.action_release("move_forward")
	check(sled.boost_energy < 100, "boost consumes energy")
	var spent: float = sled.boost_energy
	await frames(30)
	check(sled.boost_energy > spent, "boost recharges when released")
	# Checkpoint Area3D filters backward crossings before delegating to race.
	tracker.setup(track.CHECKPOINT_COUNT)
	var area: Area3D
	for child in track.get_children():
		if child is Area3D and child.checkpoint_index == 0:
			area = child
	sled.velocity = -area.forward * 8
	area._on_body_entered(sled)
	check(not tracker.has_started, "backward start crossing is rejected")
	sled.velocity = area.forward * 8
	area._on_body_entered(sled)
	check(tracker.has_started, "forward start crossing is accepted")
	# Drive real physics through the first checkpoint volume.
	var cp_progress := 1.0 / track.CHECKPOINT_COUNT
	sled.reset_to(track.frame_at(cp_progress - 0.012))
	Input.action_press("move_forward")
	await frames(120)
	Input.action_release("move_forward")
	check(tracker.last_checkpoint >= 1, "moving sled triggers the real checkpoint Area3D")
	# Deterministic ordering test, independent of player steering.
	tracker.setup(track.CHECKPOINT_COUNT)
	race.current_lap = 0
	race.lap_times.clear()
	race.lap_start = 0
	race.checkpoint_hit(0)
	for lap in range(3):
		for index in range(1, track.CHECKPOINT_COUNT):
			race.checkpoint_hit(index)
		check(race.current_lap == lap, "lap %d waits for the finish line" % (lap + 1))
		race.race_time = float(lap + 1) * 60
		race.checkpoint_hit(0)
	check(race.state == race.RaceState.FINISHED, "third full lap finishes the race")
	check(race.lap_times.size() == 3, "results contain three lap splits")
	check(not race.checkpoint_hit(1), "finished races reject extra checkpoints")
	await frames(150)
	Input.action_press("move_forward")
	await frames(90)
	Input.action_release("move_forward")
	check(sled.get_speed_kph() < 1, "finish prevents further driving")
	race.restart()
	check(race.current_lap == 0 and race.race_time == 0, "restart clears the race")
	check(not tracker.has_started and tracker.next_checkpoint == 0, "restart resets start-line validation")
	check(sled.boost_energy == 100, "restart restores boost energy")
	race.menu()
	check(race.state == race.RaceState.MENU and not paused, "return to basecamp works")
	# Exercise production persistence with a disposable, isolated save path.
	var original_path: String = state.save_path
	state.save_path = "user://smoke_%d.cfg" % Time.get_ticks_usec()
	state.best_time = 0.0
	state.best_lap = 0.0
	state.practice_run = false
	check(state.record_run(90, 28), "first completed run sets a record")
	check(not state.save_error, "record save succeeds")
	state.best_time = 0
	state.best_lap = 0
	state.load_records()
	check(state.best_time == 90 and state.best_lap == 28, "saved records survive reload")
	check(not state.record_run(100, 30), "slower runs preserve the best time")
	check(state.best_time == 90 and state.best_lap == 28, "slower records are not overwritten")
	check(state.record_run(80, 25), "faster run improves both records")
	state.load_records()
	check(state.best_time == 80 and state.best_lap == 25, "improved records persist")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(state.save_path))
	state.save_path = original_path
	state.load_records()
	state.practice_run = true
	print("SMOKE RESULT: %d checks, %d failures" % [checks, failures])
	scene.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
