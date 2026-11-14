extends SceneTree
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
	var settings: Node = root.get_node("GameState")
	settings.practice_run = true
	settings.difficulty = 1
	settings.race_mode = 0
	settings.breed = 0
	settings.sled_style = 3
	for course in range(4):
		settings.course = course
		settings.camera_modes = [0, 0]
		var scene: Node3D = load("res://scenes/main/Main.tscn").instantiate()
		root.add_child(scene)
		current_scene = scene
		await frames(90)
		await capture("update-garage-%d.png" % course)
		var race: Node = scene.get_node("RaceManager")
		var track: AlpineTrack = scene.get_node("Track")
		var camera: Camera3D = scene.get_node("ChaseCamera")
		race.start()
		race.countdown = 0.01
		await frames(8)
		var pose := track.frame_at(0.15)
		race.sled.reset_to(pose)
		camera.snap()
		await frames(30)
		settings.camera_modes[0] = 1
		await frames(50)
		await capture("update-pov-%d.png" % course)
		# A close view of the roadside figures and smoother geometry.
		var life: Node3D = track.get_child(track.get_child_count() - 1)
		if life.get_child_count() > 0:
			var prop: Node3D = life.get_child(0)
			camera.set_physics_process(false)
			camera.global_position = prop.global_position + prop.global_basis * Vector3(8, 5, -12)
			camera.look_at(prop.global_position + Vector3.UP * 2)
			camera.fov = 50
			scene.get_node("HUD").visible = false
			await frames(10)
			await capture("update-landmark-%d.png" % course)
		scene.queue_free()
		await frames(3)
	settings.race_mode = 1
	settings.course = 3
	settings.breed2 = 1
	settings.sled_style2 = 1
	settings.camera_modes = [0, 0]
	var scene: Node3D = load("res://scenes/main/Main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await frames(90)
	await capture("update-duel-garage.png")
	var race: Node = scene.get_node("RaceManager")
	race.start()
	race.countdown = 0.01
	await frames(60)
	settings.camera_modes[1] = 1
	await frames(30)
	await capture("update-split-screen.png")
	scene.queue_free()
	await frames(3)
	quit()
