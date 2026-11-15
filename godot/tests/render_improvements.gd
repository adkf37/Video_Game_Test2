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
	settings.race_mode = 0
	settings.course = 0
	settings.breed = 3
	settings.sled_style = 0
	settings.difficulty = 1
	settings.camera_modes = [0, 0]
	var scene: Node3D = load("res://scenes/main/Main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await frames(30)
	await capture("new-solo-basecamp.png")
	var race: Node = scene.get_node("RaceManager")
	var camera: Camera3D = scene.get_node("ChaseCamera")
	camera.set_physics_process(false)
	scene.get_node("HUD").visible = false
	race.sled.reset_to(scene.get_node("Track").frame_at(0.25))
	await frames(40)
	race.sled.set_physics_process(false)
	for breed in range(4):
		settings.breed = breed
		race.apply_customization()
		await frames(3)
		for other in race.sled.visual.dogs:
			other.visible = false
		race.sled.visual.musher.visible = false
		var dog: Node3D = race.sled.visual.dogs[0]
		dog.visible = true
		var scale: float = [1.0, 0.85, 1.38, 0.62][breed]
		var focus := dog.global_position + Vector3.UP * scale * 0.9
		camera.global_position = focus + race.sled.global_basis * Vector3(2.0, 0.8, -3.0) * scale
		camera.look_at(focus)
		camera.fov = 43
		await create_timer(0.8).timeout
		await capture("new-breed-%d.png" % breed)
	scene.queue_free()
	await frames(3)
	for course in range(4):
		settings.course = course
		scene = load("res://scenes/main/Main.tscn").instantiate()
		root.add_child(scene)
		current_scene = scene
		await frames(8)
		scene.get_node("HUD").visible = false
		camera = scene.get_node("ChaseCamera")
		camera.set_physics_process(false)
		var life: Node3D = scene.get_node("Track/TrackLife")
		var prop: Node3D = life.get_child(1)
		var height := 2.0 if course in [1, 2] else 0.9
		camera.global_position = prop.global_position + prop.global_basis * Vector3(5, height + 2, -7)
		camera.look_at(prop.global_position + Vector3.UP * height)
		camera.fov = 42
		await frames(10)
		await capture("new-spectator-%d.png" % course)
		scene.queue_free()
		await frames(3)
	quit()
