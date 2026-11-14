extends SceneTree
var failures := 0
var checks := 0
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)
func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
func key(code: int, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = down
	Input.parse_input_event(event)
func _run() -> void:
	var settings: Node = root.get_node("GameState")
	settings.practice_run = true
	settings.race_mode = 1
	settings.course = 3
	settings.difficulty = 1
	settings.sled_style = 3
	settings.breed2 = 3
	settings.sled_style2 = 2
	settings.camera_modes = [0, 0]
	var scene: Node3D = load("res://scenes/main/Main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await frames(8)
	var race: Node = scene.get_node("RaceManager")
	var track: AlpineTrack = scene.get_node("Track")
	var split: Node = scene.get_node("SplitScreen")
	check(race.players.size() == 2 and race.rivals.size() == 2, "local duel creates two humans and two rivals")
	check(race.players[1].visual.dogs.size() == 12 and race.players[1].visual.sled_style == 2, "player two gets independent garage choices")
	check(race.sled.visual.musher.position.z < -2, "throne musher stands in front of the chair")
	check(split.containers.size() == 2 and not split.active, "garage uses one view before racing")
	var lows := 1000.0
	var highs := -1000.0
	for point in track.points:
		lows = minf(lows, point.y)
		highs = maxf(highs, point.y)
	check(highs - lows > 12, "city course has substantial climbs and descents")
	var limits := []
	for depth: float in [0.0, 3.0, 6.0, 10.0, 14.0]:
		limits.append(RaceCatalog.offroad_limit(track.half_width + depth, track.half_width, 1))
	check(limits[0] == 25 and limits[1] > limits[2] and limits[2] > limits[3] and limits[3] > limits[4] and limits[4] == 8, "off-track slowdown increases continuously through both cuts")
	var space := InputEventKey.new()
	space.keycode = KEY_SPACE
	var unmapped := true
	for action in InputMap.get_actions():
		if action.begins_with("p1_") or action.begins_with("p2_") or action == "boost":
			if InputMap.event_is_action(space, action):
				unmapped = false
	check(unmapped, "space is unassigned to both racers")
	race.start()
	race.countdown = 0.01
	await frames(8)
	check(split.active and split.cameras[0].target != split.cameras[1].target, "split cameras follow separate racers in one world")
	var p1: CharacterBody3D = race.players[0]
	var p2: CharacterBody3D = race.players[1]
	var p1_start := p1.global_position
	key(KEY_UP, true)
	await frames(100)
	key(KEY_UP, false)
	await frames(3)
	check(p2.current_speed > 10 and p1.global_position.distance_to(p1_start) < 0.5, "arrow throttle moves only player two")
	var saved_p2_speed: float = p2.current_speed
	key(KEY_W, true)
	await frames(40)
	key(KEY_W, false)
	await frames(3)
	check(p1.current_speed > 5 and p2.current_speed < saved_p2_speed, "W throttle moves only player one")
	key(KEY_SLASH, true)
	key(KEY_UP, true)
	await frames(15)
	check(p2.boosting and not p1.boosting, "player two boost is independent")
	key(KEY_SLASH, false)
	key(KEY_UP, false)
	key(KEY_C, true)
	await frames(3)
	key(KEY_C, false)
	await frames(3)
	check(settings.camera_modes == [1, 0], "C switches only player one to musher view")
	key(KEY_ENTER, true)
	await frames(3)
	key(KEY_ENTER, false)
	await frames(3)
	check(settings.camera_modes == [1, 1], "Enter switches only player two to musher view")
	check(not split.cameras[0].get_cull_mask_value(2) and split.cameras[1].get_cull_mask_value(2), "POV hides only its own musher")
	key(KEY_ESCAPE, true)
	await process_frame
	await process_frame
	key(KEY_ESCAPE, false)
	await process_frame
	var before := p2.position
	var time: float = race.player_times[1]
	await frames(10)
	check(paused and p2.position.is_equal_approx(before) and race.player_times[1] == time, "pause freezes both players and clocks")
	race.resume()
	var player1_time: float = race.player_times[0]
	var player2_time: float = race.player_times[1]
	race.recover(1)
	check(race.player_times[1] == player2_time + 3 and race.player_times[0] == player1_time, "recovery penalty belongs only to the recovering player")
	# Validate independent finish lifecycle without waiting for a full circuit.
	race.player_trackers[0].current_lap = 3
	race._human_lap(0, 3)
	check(race.state == race.RaceState.RACING and not p1.can_drive() and p2.can_drive(), "first human finish leaves the other racing")
	var finished_time: float = race.player_times[0]
	await frames(10)
	check(race.player_times[0] == finished_time and race.player_times[1] > player2_time, "finished player's clock stops independently")
	race.player_trackers[1].current_lap = 3
	race._human_lap(1, 3)
	check(race.state == race.RaceState.FINISHED and race.finish_order.has(p1) and race.finish_order.has(p2), "results wait for both humans")
	check(not race.new_record, "duels do not overwrite solo records")
	race.restart()
	await frames(3)
	check(race.finish_order.is_empty() and race.player_trackers[1].current_lap == 0 and race.player_times == [0.0, 0.0], "restart resets both racers and their clocks")
	race.menu()
	await frames(3)
	check(not split.active and scene.get_node("ChaseCamera").is_current(), "return to garage restores single preview camera")
	scene.queue_free()
	await process_frame
	print("DUEL RESULT: ", checks, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)
