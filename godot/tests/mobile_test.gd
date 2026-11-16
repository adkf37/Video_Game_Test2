extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, message: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", message)
	if not ok:
		failures += 1
func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
func _run() -> void:
	var settings: Node = root.get_node("GameState")
	settings.practice_run = true
	settings.mobile_mode = true
	settings.race_mode = 0
	settings.course = 0
	settings.difficulty = 0
	settings.mobile_input = preload("res://scripts/core/MobileBridge.gd").new()
	settings.add_child(settings.mobile_input)
	var bridge: Node = settings.mobile_input
	var scene: Node3D = load("res://scenes/main/Main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await frames(10)
	var race: Node = scene.get_node("RaceManager")
	check(bridge.manager == race and bridge.ready_sent, "mobile bridge waits for the complete grid")
	check(race.players.size() == 1 and race.rivals.size() == 3, "mobile uses solo racing against three rivals")
	check(not scene.get_node("HUD").visible and not scene.get_node("Sun").shadow_enabled, "phone uses HTML controls and lighter graphics")
	bridge.command({"type": "input", "steer": 5, "boost": true})
	var controls: Dictionary = race.sled.drive_controls(0.016)
	check(controls.steer == 1 and controls.throttle == 1 and controls.boost, "mobile input clamps steering and auto-accelerates")
	bridge.command({"type": "input", "brake": true, "drift": true})
	check(bridge.controls().throttle == -1 and bridge.controls().drift, "mobile brake/reverse and drift reach sled controls")
	bridge.clear_controls()
	check(not bridge.controls().drift, "released controls clear drift")
	bridge.command({"type": "start"})
	bridge.command({"type": "input", "steer": 0})
	check(race.state == race.RaceState.COUNTDOWN, "explicit start begins countdown")
	race.countdown = 0.01
	await frames(15)
	check(race.sled.current_speed > 1, "real sled accelerates without keyboard input")
	bridge.command({"type": "throw"})
	check(bridge.controls().throw_item and not bridge.controls().throw_item, "bone press is consumed exactly once")
	bridge.command({"type": "input", "steer": -0.5, "boost": true})
	bridge.command({"type": "pause"})
	check(paused and race.state == race.RaceState.PAUSED and not bridge.boost and bridge.steer == 0, "pause releases held mobile controls")
	var time: float = race.race_time
	await frames(10)
	check(race.race_time == time, "mobile pause freezes the race clock")
	bridge.command({"type": "resume"})
	bridge.command({"type": "input", "steer": 0})
	check(not paused and race.state == race.RaceState.RACING, "explicit resume restores racing")
	bridge.command({"type": "recover"})
	check(race.race_time == time + 3, "mobile recovery applies the normal penalty")
	bridge.command({"type": "camera"})
	check(settings.camera_modes[0] == 1, "phone can switch to musher view")
	var was_muted: bool = settings.muted
	bridge.command({"type": "mute"})
	check(settings.muted != was_muted, "mobile sound toggle uses the game mixer")
	bridge.since_input = 0.8
	check(bridge.controls().throttle == 0 and not bridge.controls().boost, "lost input stops acceleration and boost")
	bridge._process(0.8)
	check(paused and race.state == race.RaceState.PAUSED, "lost parent connection automatically pauses racing")
	bridge.command({"type": "resume"})
	bridge.command({"type": "input", "steer": 0})
	race.elapsed_time = 110
	race.player_times[0] = 110
	race.player_trackers[0].current_lap = 3
	race._human_lap(0, 3)
	var state: Dictionary = bridge.snapshot()
	check(state.state == race.RaceState.FINISHED and state.results.size() == 4, "mobile results include the complete solo field")
	bridge.command({"type": "start"})
	check(race.state == race.RaceState.COUNTDOWN and race.finish_order.is_empty(), "mobile replay resets the race")
	paused = false
	scene.queue_free()
	bridge.queue_free()
	settings.mobile_input = null
	settings.mobile_mode = false
	await process_frame
	print("MOBILE RESULT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
