extends SceneTree
## Exercise autonomous rivals, finish order and a winnable race through physics.
var failures := 0
var checks := 0
var scene: Node3D

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)
	else:
		print("PASS: " + message)

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame

func _run() -> void:
	root.get_node("GameState").practice_run = true
	scene = load("res://scenes/main/Main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await frames(20)
	var race: Node = scene.get_node("RaceManager")
	var sled: CharacterBody3D = scene.get_node("PlayerSled")
	var track: AlpineTrack = scene.get_node("Track")
	check(race.rivals.size() == 3, "three rivals spawn")
	check(get_nodes_in_group("player").size() == 1, "NPCs do not masquerade as the player")
	check(race.player_position() == 4, "player starts behind the rival grid")
	sled.position = track.frame_at(-0.001).origin
	race.lap_tracker.checkpoint_hit(0)
	check(is_zero_approx(race.race_progress(sled)), "start-line trigger does not jump a sector in standings")
	race.rivals[0].position = track.frame_at(0.02).origin
	race.rivals[0].lap_tracker.checkpoint_hit(0)
	check(race.player_position() > 1, "rival ahead remains ahead while player crosses start")
	race.start()
	var grid: Array[Vector3] = []
	for rival in race.rivals:
		grid.append(rival.position)
	await frames(45)
	for i in range(3):
		check(Vector2(race.rivals[i].position.x, race.rivals[i].position.z).distance_to(Vector2(grid[i].x, grid[i].z)) < 0.5, "rival %d waits for the countdown" % i)
	race.countdown = 0.01
	await frames(3)
	check(not race.checkpoint_hit(7, race.rivals[0]), "NPC cannot skip checkpoints")
	check(race.lap_tracker.next_checkpoint == 0, "NPC checkpoint calls do not advance player laps")
	race.register_finish(race.rivals[0])
	check(race.finish_order.is_empty(), "unfinished rival cannot register a result")
	await frames(90)
	check(race.rivals[0].get_speed_kph() > 20, "NPC accelerates using shared sled physics")
	Input.action_press("pause")
	await process_frame
	Input.action_release("pause")
	await process_frame
	var frozen: Vector3 = race.rivals[0].position
	var frozen_time: float = race.elapsed_time
	await frames(10)
	check(race.rivals[0].position.is_equal_approx(frozen) and race.elapsed_time == frozen_time, "pause freezes NPCs and competition clock")
	race.resume()
	Engine.time_scale = 4.0
	for tick in range(2700):
		await physics_frame
		if race.finish_order.size() == 3:
			break
		if tick % 900 == 0:
			for rival in race.rivals:
				print("NPC DRIVE: ", rival.racer_name, " lap=", rival.lap_tracker.current_lap, " next=", rival.lap_tracker.next_checkpoint, " offset=", rival.route_distance)
	for rival in race.rivals:
		check(rival.finished and rival.lap_tracker.current_lap == 3, rival.racer_name + " completes three real laps")
		check(rival.recovery_count == 0, rival.racer_name + " completes without teleport recovery")
	check(race.finish_order.size() == 3 and race.player_position() == 4, "NPCs can beat an idle player")
	check(race.current_lap == 0 and race.state == race.RaceState.RACING, "rival finishes do not end the player's race")
	var completed: Array = race.finish_order.duplicate()
	race.register_finish(race.rivals[0])
	check(race.finish_order == completed, "duplicate finishes are ignored")
	race.restart()
	check(race.finish_order.is_empty() and race.elapsed_time == 0, "restart clears standings and race clock")
	for rival in race.rivals:
		check(not rival.finished and rival.lap_tracker.current_lap == 0 and rival.boost_energy == 100, rival.racer_name + " resets for the rematch")
	race.countdown = 0.01
	var best_position := 4
	# A competent player uses straights for boost and wins through actual driving.
	for tick in range(3000):
		await physics_frame
		if race.state == race.RaceState.FINISHED:
			break
		var near := track.nearest(sled.position)
		var goal := track.frame_at(near.progress + 10.0 / track.total_length).origin
		var forward := -sled.global_basis.z
		var direction := (goal - sled.position).normalized()
		direction.y = 0
		forward.y = 0
		var angle := forward.signed_angle_to(direction, Vector3.UP)
		var steer := clampf(-angle * 2.5, -1, 1)
		Input.action_press("turn_left", maxf(-steer, 0))
		Input.action_press("turn_right", maxf(steer, 0))
		Input.action_press("move_forward", 1.0)
		if absf(angle) < 0.1 and sled.boost_energy > 15:
			Input.action_press("boost")
		else:
			Input.action_release("boost")
		best_position = mini(best_position, race.player_position())
	for action in ["move_forward", "turn_left", "turn_right", "boost"]:
		Input.action_release(action)
	check(race.state == race.RaceState.FINISHED, "player completes the four-team race")
	check(best_position == 1 and race.player_finish_place == 1, "skilled driving can overtake all rivals and win")
	var locked_place: int = race.player_finish_place
	for tick in range(1800):
		await physics_frame
		if race.finish_order.size() == 4:
			break
	check(race.finish_order.size() == 4, "remaining rivals finish after player results open")
	check(race.player_finish_place == locked_place and race.player_position() == locked_place, "player result stays locked after other teams finish")
	var previous := -1.0
	for row in race.standings():
		print("RESULT: ", row.name, " ", row.time)
		check(row.finished and row.time >= previous, "finish table has chronological times")
		previous = row.time
	race.menu()
	var menu_position: Vector3 = race.rivals[0].position
	await frames(20)
	check(race.rivals[0].position.distance_to(menu_position) < 1.0, "rivals wait at basecamp")
	print("NPC RESULT: %d checks, %d failures" % [checks, failures])
	scene.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
