extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var settings: Node = root.get_node("GameState")
	settings.practice_run = true
	settings.course = 0
	settings.race_mode = 0
	for difficulty in range(3):
		settings.difficulty = difficulty
		var scene: Node = load("res://scenes/main/Main.tscn").instantiate()
		root.add_child(scene)
		current_scene = scene
		for i in range(8):
			await physics_frame
		var race: Node = scene.get_node("RaceManager")
		var track: AlpineTrack = scene.get_node("Track")
		race.start()
		race.state = race.RaceState.RACING
		race.items.set_physics_process(false)
		race.hazards.set_physics_process(false)
		for rival in race.rivals:
			rival.set_physics_process(false)
			rival.collision_layer = 0
		var passages: Array[Vector2] = []
		for i in range(12):
			for side: float in [-1, 1]:
				passages.append(Vector2(float(i) / 12 + 0.025, side * (track.half_width + 0.6)))
		for progress: float in [0.23, 0.52, 0.73]:
			passages.append(Vector2(progress, -10))
		for passage in passages:
			var frame := track.frame_at(passage.x)
			frame.origin += frame.basis.x * passage.y + frame.basis.z * 4
			frame.origin.y = track.ground_height(frame.origin)
			race.sled.reset_to(frame)
			race.sled.current_speed = 18
			race.sled.drive_velocity = -race.sled.global_basis.z * 18
			var start: Vector3 = race.sled.position
			Input.action_press("move_forward")
			for i in range(60):
				await physics_frame
			Input.action_release("move_forward")
			var travel: float = (race.sled.position - start).dot(-frame.basis.z)
			if travel < 8:
				failures += 1
				push_error("Marker blocked passage: difficulty=%d progress=%.3f lane=%.1f travel=%.2f" % [difficulty, passage.x, passage.y, travel])
		print("MARKER PASSAGES: 27 driven at difficulty ", difficulty)
		scene.queue_free()
		await process_frame
	print("PASSAGE RESULT: ", failures, " failures")
	quit(0 if failures == 0 else 1)
