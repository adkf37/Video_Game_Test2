extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var settings: Node = root.get_node("GameState")
	settings.practice_run = true
	settings.race_mode = 0
	settings.difficulty = 1
	settings.muted = true
	for course in range(4):
		settings.course = course
		var scene: Node3D = load("res://scenes/main/Main.tscn").instantiate()
		root.add_child(scene)
		current_scene = scene
		for i in range(12):
			await process_frame
		var race: Node = scene.get_node("RaceManager")
		var hazards: Node3D = race.hazards
		var hazard: Dictionary = hazards.hazards[0]
		var frame: Transform3D = hazard.frame
		scene.get_node("HUD").visible = false
		for racer in get_nodes_in_group("racers"):
			racer.set_physics_process(false)
			racer.visible = false
		hazards.set_physics_process(false)
		hazards.elapsed = 5
		hazards._update_hazard(hazard, true)
		if course == 1:
			race.state = race.RaceState.RACING
			race.sled.route_progress = hazard.progress - 25.0 / hazards.track.total_length
			race.sled.reset_to(hazards.track.frame_at(race.sled.route_progress))
			race.sled.current_speed = 16
			hazards._try_coconut(hazard)
			hazards._update_coconuts(1.10)
		var camera: Camera3D = scene.get_node("ChaseCamera")
		camera.set_physics_process(false)
		camera.global_position = frame.origin + frame.basis.z * 17 + Vector3.UP * 12 - frame.basis.x * 5
		camera.look_at(frame.origin + Vector3.UP * 1.5 + frame.basis.x * (3 if course in [1, 2] else 0))
		camera.fov = 62
		for i in range(5):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../artifacts/hazard-%d.png" % course))
		print("RENDER HAZARD ", course)
		scene.queue_free()
		await process_frame
	# Let the audio server release the final Ogg playback before tree teardown.
	await create_timer(0.3).timeout
	quit()
