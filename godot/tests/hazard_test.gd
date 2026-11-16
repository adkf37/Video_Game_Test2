extends SceneTree
var failures := 0
var checks := 0
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, message: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", message)
	if not ok:
		failures += 1
func frames(n: int) -> void:
	for i in range(n):
		await physics_frame
func _run() -> void:
	var settings: Node = root.get_node("GameState")
	settings.practice_run = true
	settings.race_mode = 1
	settings.difficulty = 2
	settings.muted = false
	for course in range(4):
		settings.course = course
		var scene: Node3D = load("res://scenes/main/Main.tscn").instantiate()
		root.add_child(scene)
		current_scene = scene
		await frames(8)
		var race: Node = scene.get_node("RaceManager")
		var track: AlpineTrack = scene.get_node("Track")
		var hazards: Node3D = race.hazards
		var p1: CharacterBody3D = race.players[0]
		var p2: CharacterBody3D = race.players[1]
		var sound: Node = scene.get_node("RaceAudio")
		check(race.items.pickups.size() == 3, "three scarce bones on course %d" % course)
		check(sound.music.stream == sound.layers and sound.layers.stream_count == 2 and sound.SCORES[course][0].loop and sound.SCORES[course][1].loop,
			"course score has looping melody and drum layers")
		for racer in get_nodes_in_group("racers"):
			racer.set_physics_process(false)
			racer.collision_layer = 0
			racer.position = Vector3(500, 0, 500)
		hazards.set_physics_process(false)
		race.start()
		var initial_time: float = hazards.elapsed
		hazards._physics_process(1)
		check(hazards.elapsed == initial_time, "countdown holds hazards")
		race.state = race.RaceState.RACING
		var hazard: Dictionary = hazards.hazards[0]
		hazards.elapsed = 1.0
		hazards._update_hazard(hazard, true)
		if course != 1:
			check(hazard.warning and not hazard.active, "warning precedes collision on course %d" % course)
			hazards.elapsed = 5.0
			hazards._update_hazard(hazard, true)
			check(hazard.active, "obstacle enters track on course %d" % course)
			if course == 2:
				check(hazard.width * 2 <= track.half_width and absf(hazard.lane) - hazard.width >= 0,
					"fallen candy leaves at least half of the road open on Hard")
			var frame: Transform3D = hazard.frame
			p1.reset_to(frame)
			p1.position = frame * Vector3(hazard.lane, 0.5, 0)
			p1.current_speed = 30
			hazards.previous_positions[p1] = frame * Vector3(hazard.lane, 0.5, 5)
			check(hazards._contact(hazard, p1) and p1.current_speed == 0 and p1.hazard_time == 1.0, "obstacle gives exactly a one-second stop")
			var hit_count: int = p1.hazard_hits
			p1.position = frame * Vector3(hazard.lane, 0.5, 0)
			hazards._contact(hazard, p1)
			check(p1.hazard_hits == hit_count and p1.position.is_equal_approx(frame * Vector3(hazard.lane, 0.5, 0)),
				"continued contact never pushes the sled backward")
			p1.hazard_immunity = 0
			p1.hazard_time = 0
			hazards._contact(hazard, p1)
			check(p1.hazard_hits == hit_count, "staying inside an obstacle never starts another delay after immunity expires")
			p1.position = frame * Vector3(hazard.lane, 0.5, -10)
			hazards.previous_positions[p1] = p1.position
			hazards._contact(hazard, p1)
			p1.position = frame * Vector3(hazard.lane, 0.5, 0)
			hazards.previous_positions[p1] = p1.position
			check(hazards._contact(hazard, p1) and p1.hazard_hits == hit_count + 1, "a later separate crossing can trigger a new delay")
			p1.set_physics_process(true)
			Input.action_press("p1_move_forward")
			var stopped_at: Vector3 = p1.position
			await frames(30)
			check(p1.hazard_time > 0.4 and p1.current_speed == 0, "crossing obstacle holds the team during its one-second delay")
			for step in range(95):
				await physics_frame
				hazards._contact(hazard, p1)
			check(p1.hazard_time == 0 and (p1.position - stopped_at).dot(-frame.basis.z) > 3, "holding forward clears the obstacle without backing up")
			Input.action_release("p1_move_forward")
			p1.set_physics_process(false)
			p2.reset_to(frame)
			p2.position = frame * Vector3(-signf(hazard.lane + 0.01) * track.half_width * 0.8, 0.5, 0)
			hazards.previous_positions[p2] = p2.position
			check(not hazards._contact(hazard, p2), "clear lane permits dodging")
		else:
			p1.reset_to(track.frame_at(hazard.progress - 25.0 / track.total_length))
			p1.route_progress = hazard.progress - 25.0 / track.total_length
			p1.current_speed = 16
			hazards._try_coconut(hazard)
			check(hazards.coconuts.size() == 1, "lemur throws at an approaching team")
			var coconut: Dictionary = hazards.coconuts[0]
			check(coconut.marker.visible and p1.hazard_time == 0, "landing marker warns before projectile hits")
			p1.position = coconut.end + Vector3.UP * 0.5
			p2.position = coconut.end + Vector3(5, 0.5, 0)
			hazards._update_coconuts(1.61)
			check(p1.hazard_time == 1.0 and p2.hazard_time == 0, "coconut hits only its landing area for one second")
			p1.set_physics_process(true)
			await frames(30)
			check(p1.hazard_time > 0.4 and p1.current_speed == 0, "coconut actually stops the team")
			race.resume_state = race.RaceState.RACING
			race.state = race.RaceState.PAUSED
			paused = true
			var timer: float = p1.hazard_time
			await frames(10)
			check(p1.hazard_time == timer, "pause freezes coconut stun")
			race.resume()
			await frames(65)
			check(p1.hazard_time == 0 and p1.hazard_immunity > 0, "control returns after one second with protection")
			p1.set_physics_process(false)
		var events: int = sound.effect_count
		sound.cooldowns.clear()
		sound.event("pickup", 0)
		sound.event("pickup", 1)
		check(sound.effect_count == events + 2, "both human players receive event sounds")
		settings.muted = true
		sound.event("boost")
		check(sound.effect_count == events + 2, "mute suppresses event sounds")
		settings.muted = false
		p1.hit_hazard("coconut")
		race.restart()
		check(hazards.elapsed == 0 and hazards.coconuts.is_empty() and p1.hazard_time == 0, "restart clears hazards and effects")
		scene.queue_free()
		await process_frame
	print("HAZARD RESULT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
