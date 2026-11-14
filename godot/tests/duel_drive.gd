extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var settings: Node = root.get_node("GameState")
	settings.practice_run = true
	settings.race_mode = 1
	settings.difficulty = 1
	settings.course = 3
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--course="):
			settings.course = int(arg.get_slice("=", 1))
	var scene: Node3D = load("res://scenes/main/Main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	var race: Node = scene.get_node("RaceManager")
	var track: AlpineTrack = scene.get_node("Track")
	for i in range(10):
		await physics_frame
	race.start()
	race.countdown = 0.01
	Engine.time_scale = 4.0
	var maximum := 0.0
	for tick in range(6000):
		await physics_frame
		if race.state == race.RaceState.FINISHED:
			break
		for i in range(2):
			var player: CharacterBody3D = race.players[i]
			var prefix: String = player.input_prefix()
			var near_point := track.nearest(player.position)
			maximum = maxf(maximum, near_point.distance)
			var frame := track.frame_at(near_point.progress + 10.0 / track.total_length)
			var goal := frame.origin + frame.basis.x * (-1.5 if i == 0 else 1.5)
			var direction := goal - player.position
			direction.y = 0
			var forward := -player.global_basis.z
			forward.y = 0
			var steer := clampf(-forward.signed_angle_to(direction.normalized(), Vector3.UP) * 2.5, -1, 1)
			Input.action_press(prefix + "turn_left", maxf(-steer, 0))
			Input.action_press(prefix + "turn_right", maxf(steer, 0))
			Input.action_press(prefix + "move_forward", 0.82 + i * 0.03)
		if tick % 1800 == 0:
			print("DUEL DRIVING ", settings.course, " laps ", race.player_trackers[0].current_lap, "/", race.player_trackers[1].current_lap)
	for prefix in ["p1_", "p2_"]:
		for action in ["turn_left", "turn_right", "move_forward"]:
			Input.action_release(prefix + action)
	var success: bool = race.state == race.RaceState.FINISHED and race.player_trackers[0].current_lap == 3 and race.player_trackers[1].current_lap == 3
	print("DUEL DRIVE ", settings.course, " RESULT: ", success, " max_offset=", maximum, " order=", race.player_finish_place)
	scene.queue_free()
	await process_frame
	quit(0 if success else 1)
