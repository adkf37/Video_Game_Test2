extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, message: String) -> void:
	print("PASS: " if ok else "FAIL: ", message)
	if not ok:
		failures += 1
func _run() -> void:
	var settings: Node = root.get_node("GameState")
	settings.practice_run = true
	settings.race_mode = 0
	for difficulty in range(3):
		settings.difficulty = difficulty
		var scene: Node3D = load("res://scenes/main/Main.tscn").instantiate()
		root.add_child(scene)
		current_scene = scene
		for i in range(8):
			await physics_frame
		var race: Node = scene.get_node("RaceManager")
		race.start()
		race.state = race.RaceState.RACING
		for racer in get_nodes_in_group("racers"):
			racer.set_physics_process(false)
		var paces: Array = race.rivals.map(func(rival): return rival.cruise_throttle)
		paces.sort()
		check(is_equal_approx(paces[1], RaceCatalog.NPC_PACE[difficulty] * 1.25) and paces[0] < paces[1] and paces[1] < paces[2], "shuffled field retains difficulty and distinct paces")
		var favorite: int = race.previous_favorite
		race.start()
		check(race.previous_favorite != favorite, "rematch gives a different NPC the strongest pace")
		race.state = race.RaceState.RACING
		race.elapsed_time = 100
		race.player_times[0] = 103
		var winner: Node = race.rivals[0]
		winner.finished = true
		winner.lap_tracker.current_lap = 3
		race.register_finish(winner)
		race.elapsed_time = 110
		for i in [1, 2]:
			race.rivals[i].lap_tracker.has_started = true
			race.rivals[i].lap_tracker.current_lap = 2
			race.rivals[i].lap_tracker.lap_travel = 0.8 if i == 1 else 0.3
		race.player_trackers[0].current_lap = 3
		race._human_lap(0, 3)
		check(race.state == race.RaceState.FINISHED and race.finish_order.size() == 4, "solo finish resolves entire field immediately")
		check(race.finish_times[winner] == 100 and not race.estimated_finishes.has(winner), "actual earlier finish is preserved")
		check(race.player_finish_place == 2 and race.finish_order[2] == race.rivals[1], "actual placement and remaining order preserved")
		var rows: Array = race.standings()
		check(rows[2].estimated and rows[3].estimated and rows[2].time > 110 and rows[3].time > rows[2].time, "remaining NPCs have sensible labeled estimates")
		var hud: Node = scene.get_node("HUD")
		check(hud.result_details.text.contains("est.") and not hud.result_details.text.contains("Racing..."), "results explain estimates and never wait for solo rivals")
		check(not race.rivals[1].can_drive() and not race.rivals[2].can_drive(), "estimated rivals stop racing")
		race.restart()
		check(race.estimated_finishes.is_empty() and race.finish_order.is_empty(), "restart clears estimated results")
		scene.queue_free()
		await process_frame
	print("SOLO RESULTS: ", failures, " failures")
	quit(0 if failures == 0 else 1)
