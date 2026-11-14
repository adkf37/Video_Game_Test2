extends SceneTree
## Render reproducible previews without writing player records.
var scene: Node3D
func _initialize() -> void:
	call_deferred("_run")
func settle(count: int) -> void:
	for i in range(count):
		await process_frame
func capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../artifacts/" + filename)
	root.get_texture().get_image().save_png(path)
	print("PREVIEW: ", path)
func _run() -> void:
	root.get_node("GameState").practice_run = true
	scene = load("res://scenes/main/Main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await settle(120)
	await capture("basecamp.png")
	var race: Node = scene.get_node("RaceManager")
	var sled: CharacterBody3D = scene.get_node("PlayerSled")
	var track: AlpineTrack = scene.get_node("Track")
	race.start()
	race.countdown = 0.01
	for tick in range(550):
		await physics_frame
		var near := track.nearest(sled.position)
		var goal := track.frame_at(near.progress + 10.0 / track.total_length).origin
		var forward := -sled.global_basis.z
		var direction := (goal - sled.position).normalized()
		direction.y = 0
		forward.y = 0
		var steer := clampf(-forward.signed_angle_to(direction, Vector3.UP) * 2.5, -1, 1)
		Input.action_press("turn_left", maxf(-steer, 0))
		Input.action_press("turn_right", maxf(steer, 0))
		Input.action_press("move_forward", 0.85)
		if tick == 130:
			await capture("race-start.png")
		if tick == 540:
			await capture("alpine-trail.png")
	for action in ["move_forward", "turn_left", "turn_right"]:
		Input.action_release(action)
	race.resume_state = race.state
	race.state = race.RaceState.PAUSED
	paused = true
	await settle(2)
	await capture("pause.png")
	race.resume()
	Engine.time_scale = 4.0
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
		var steer := clampf(-forward.signed_angle_to(direction, Vector3.UP) * 2.5, -1, 1)
		Input.action_press("turn_left", maxf(-steer, 0))
		Input.action_press("turn_right", maxf(steer, 0))
		Input.action_press("move_forward", 0.85)
	for action in ["move_forward", "turn_left", "turn_right"]:
		Input.action_release(action)
	for tick in range(1800):
		await physics_frame
		if race.finish_order.size() == 4:
			break
	Engine.time_scale = 1.0
	await settle(120)
	await capture("results.png")
	print("RENDER FPS: ", Engine.get_frames_per_second())
	scene.queue_free()
	await process_frame
	quit()
