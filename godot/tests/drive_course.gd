extends SceneTree
## Steering-only bot exercises the complete road and continuous lap tracking.
## No teleports, direct progress edits or records are used during the drive.
var scene: Node3D
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var state: Node = root.get_node("GameState")
	state.practice_run = true
	state.race_mode = 0
	state.difficulty = 1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--course="):
			state.course = int(arg.get_slice("=", 1))
	scene = load("res://scenes/main/Main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	var race: Node = scene.get_node("RaceManager")
	var sled: CharacterBody3D = scene.get_node("PlayerSled")
	var track: AlpineTrack = scene.get_node("Track")
	for i in range(5):
		await physics_frame
	# Isolate road traversability. Full duels and NPC races below exercise live items.
	race.items.set_physics_process(false)
	race.hazards.set_physics_process(false)
	race.start()
	race.countdown = 0.01
	Engine.time_scale = 4.0
	var max_distance := 0.0
	var previous_lap := 0
	var airborne_frames := 0
	for tick in range(12000):
		await physics_frame
		if race.state == race.RaceState.FINISHED:
			break
		var near := track.nearest(sled.position)
		max_distance = maxf(max_distance, near.distance)
		if not sled.is_on_floor():
			airborne_frames += 1
		var goal := track.frame_at(near.progress + 10.0 / track.total_length).origin
		var forward := -sled.global_basis.z
		var direction := (goal - sled.position).normalized()
		direction.y = 0
		forward.y = 0
		var angle := forward.signed_angle_to(direction, Vector3.UP)
		var steer := clampf(-angle * 2.5, -1, 1)
		Input.action_press("turn_left", maxf(-steer, 0))
		Input.action_press("turn_right", maxf(steer, 0))
		Input.action_press("move_forward", 0.85)
		if race.current_lap != previous_lap:
			previous_lap = race.current_lap
			print("DRIVE: lap ", previous_lap, " at ", race.race_time, "s")
		if tick % 1800 == 0:
			print("DRIVE: progress ", near.progress, " lap ", race.lap_tracker.current_lap, " distance ", near.distance, " speed ", sled.get_speed_kph())
		if near.distance > 25 or sled.position.y < -5:
			push_error("Bot left the trail at " + str(near.progress))
			break
	for action in ["move_forward", "turn_left", "turn_right"]:
		Input.action_release(action)
	print("DRIVE RESULT: laps=", race.current_lap, " finished=", race.state == race.RaceState.FINISHED, " max_offset=", max_distance, " airborne_frames=", airborne_frames)
	var success: bool = race.state == race.RaceState.FINISHED and max_distance < track.half_width + 14.0
	scene.queue_free()
	await process_frame
	quit(0 if success else 1)
