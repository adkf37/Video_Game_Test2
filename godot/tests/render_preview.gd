extends SceneTree
## Reproducible live garage and track previews; never writes player records.
func _initialize() -> void:
	call_deferred("_run")
func frames(n: int) -> void:
	for i in range(n):
		await process_frame
func capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../artifacts/" + filename))
	print("PREVIEW ", filename)
func _run() -> void:
	var state: Node = root.get_node("GameState")
	state.practice_run = true
	state.race_mode = 0
	state.difficulty = 1
	var choices := [[0, 0, 0, "basecamp.png"], [1, 2, 1, "jungle-mastiffs-racer.png"], [2, 3, 2, "candy-chihuahuas-chocolate.png"], [2, 1, 3, "corgis-throne.png"]]
	for choice in choices:
		state.course = choice[0]
		state.breed = choice[1]
		state.sled_style = choice[2]
		var scene: Node3D = load("res://scenes/main/Main.tscn").instantiate()
		root.add_child(scene)
		current_scene = scene
		await frames(120)
		await capture(choice[3])
		var race: Node = scene.get_node("RaceManager")
		var sled: CharacterBody3D = scene.get_node("PlayerSled")
		var track: AlpineTrack = scene.get_node("Track")
		race.start()
		race.countdown = 0.01
		for tick in range(300):
			await physics_frame
			var near := track.nearest(sled.position)
			var goal := track.frame_at(near.progress + 10 / track.total_length).origin
			var forward := -sled.global_basis.z
			var direction := (goal - sled.position).normalized()
			forward.y = 0
			direction.y = 0
			var steering := clampf(-forward.signed_angle_to(direction, Vector3.UP) * 2.5, -1, 1)
			Input.action_press("turn_left", maxf(-steering, 0))
			Input.action_press("turn_right", maxf(steering, 0))
			Input.action_press("move_forward", 0.8)
		for action in ["move_forward", "turn_left", "turn_right"]:
			Input.action_release(action)
		await capture("track-%d-breed-%d.png" % [state.course, state.breed])
		if state.course == 0:
			# Isolate a Golden Bone throw to inspect its visible arc.
			var pose := track.frame_at(0.10)
			sled.reset_to(pose)
			var rival: CharacterBody3D = race.rivals[0]
			pose.origin += pose.basis.x * 4.5
			rival.reset_to(pose)
			await physics_frame
			sled.has_bone = true
			sled.try_throw()
			await frames(3)
			await capture("golden-bone-throw.png")
		scene.queue_free()
		await frames(2)
	quit()
