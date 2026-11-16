extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var settings: Node = root.get_node("GameState")
	settings.practice_run = true
	settings.mobile_mode = true
	settings.race_mode = 0
	settings.course = 0
	settings.difficulty = 0
	settings.mobile_input = load("res://scripts/core/MobileBridge.gd").new()
	settings.add_child(settings.mobile_input)
	var bridge: Node = settings.mobile_input
	var scene: Node3D = load("res://scenes/main/Main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	for i in range(8):
		await physics_frame
	var race: Node = scene.get_node("RaceManager")
	var track: AlpineTrack = scene.get_node("Track")
	bridge.command({"type": "start"})
	bridge.command({"type": "input", "steer": 0})
	race.countdown = 0.01
	Engine.time_scale = 4
	var maximum := 0.0
	for tick in range(6000):
		await physics_frame
		if race.state == race.RaceState.FINISHED:
			break
		var near := track.nearest(race.sled.position)
		maximum = maxf(maximum, near.distance)
		var goal := track.frame_at(near.progress + 10.0 / track.total_length).origin
		var forward: Vector3 = -race.sled.global_basis.z
		var direction: Vector3 = goal - race.sled.position
		forward.y = 0
		direction.y = 0
		var steer := clampf(-forward.signed_angle_to(direction.normalized(), Vector3.UP) * 2.5, -1, 1)
		bridge.command({"type": "input", "steer": steer})
	var success: bool = race.state == race.RaceState.FINISHED and race.current_lap == 3
	print("MOBILE DRIVE RESULT: ", success, " laps=", race.current_lap, " max_offset=", maximum, " time=", race.race_time)
	scene.queue_free()
	bridge.queue_free()
	settings.mobile_input = null
	settings.mobile_mode = false
	await process_frame
	quit(0 if success else 1)
