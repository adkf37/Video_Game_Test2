extends SceneTree
## Each selected course is raced on all three difficulties by the real NPC controllers.
var failures := 0
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var state: Node = root.get_node("GameState")
	state.practice_run = true
	var course := 0
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--course="):
			course = int(arg.get_slice("=", 1))
	state.course = course
	Engine.time_scale = 4.0
	for difficulty in range(3):
		state.difficulty = difficulty
		var scene: Node3D = load("res://scenes/main/Main.tscn").instantiate()
		root.add_child(scene)
		current_scene = scene
		for i in range(10):
			await physics_frame
		var race: Node = scene.get_node("RaceManager")
		var player: Node3D = scene.get_node("PlayerSled")
		race.start()
		race.countdown = 0.01
		for tick in range(3300):
			await physics_frame
			if race.finish_order.size() == 3:
				break
			if tick % 1200 == 0:
				print("RACING ", course, "/", difficulty, " elapsed ", race.elapsed_time)
		for rival in race.rivals:
			var success: bool = rival.finished and rival.lap_tracker.current_lap == 3
			print("NPC ", course, "/", difficulty, " ", rival.racer_name, " finish=", success, " recoveries=", rival.recovery_count, " bumps=", rival.bump_count, " whips=", rival.whip_hits)
			if not success:
				failures += 1
		if race.current_lap != 0 or race.player_position() != 4:
			failures += 1
			push_error("Idle player ranking or lap state changed")
		race.restart()
		if not race.finish_order.is_empty() or race.elapsed_time != 0:
			failures += 1
		for rival in race.rivals:
			if rival.finished or rival.lap_tracker.current_lap != 0:
				failures += 1
		scene.queue_free()
		await process_frame
	print("NPC COURSE ", course, " RESULT: ", failures, " failures")
	quit(0 if failures == 0 else 1)
