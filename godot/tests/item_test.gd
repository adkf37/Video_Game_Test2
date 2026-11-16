extends SceneTree
var failures := 0
var checks := 0
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok:
		print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)
func frames(n: int) -> void:
	for i in range(n):
		await physics_frame
func _run() -> void:
	var settings: Node = root.get_node("GameState")
	settings.practice_run = true
	settings.race_mode = 1
	settings.course = 0
	settings.difficulty = 1
	var scene: Node3D = load("res://scenes/main/Main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await frames(8)
	var race: Node = scene.get_node("RaceManager")
	var track: AlpineTrack = scene.get_node("Track")
	var items: Node3D = race.items
	var p1: CharacterBody3D = race.players[0]
	var p2: CharacterBody3D = race.players[1]
	check(not InputMap.has_action("whip") and not p1.has_method("try_whip"), "whip action and attack removed")
	check(InputMap.has_action("throw_item") and InputMap.has_action("p2_throw_item"), "solo and separate duel throw inputs exist")
	race.start()
	for racer in get_nodes_in_group("racers"):
		racer.set_physics_process(false)
		racer.collision_layer = 0
		racer.global_position = Vector3(500, 0, 500)
	p1.global_position = items.pickups[0].home - Vector3.UP
	items._physics_process(0.1)
	check(not p1.has_bone, "countdown prevents collecting items")
	race.state = race.RaceState.RACING
	p1.global_position += Vector3.RIGHT * 2.0
	items._physics_process(0.1)
	check(not p1.has_bone, "passing two meters from a bone no longer collects it")
	p1.global_position = items.pickups[0].home - Vector3.UP + Vector3.RIGHT * 1.9
	items._physics_process(0.1)
	check(p1.has_bone and not p2.has_bone, "driving over a pickup fills only that racer's inventory")
	check(not items.pickups[0].node.visible and items.pickups[0].wait > 9, "pickup disappears and starts respawn timer")
	check(not p1.try_throw() and p1.has_bone, "out-of-range throw keeps the bone")
	var frame := track.frame_at(0.12)
	p1.reset_to(frame)
	var side := frame
	side.origin += frame.basis.x * 4
	p2.reset_to(side)
	p1.route_progress = 0.12
	p2.route_progress = 0.12
	check(not p1.try_throw(), "empty inventory cannot throw")
	p1.has_bone = true
	check(p1.try_throw() and not p1.has_bone, "throw consumes one collected bone")
	check(items.flights.size() == 1 and p2.bone_pending, "throw has a visible projectile and reserves its target")
	check(p2.distraction_time == 0, "distraction starts on landing, not on button press")
	items._physics_process(0.56)
	check(p2.distraction_time == 1.0 and p1.distraction_time == 0, "landing distracts only the target for one second")
	check(track.nearest(p2.distraction_goal).distance > track.half_width, "bone lands off the racing trail")
	p1.has_bone = true
	check(items.target_for(p1) == null, "chasing dog team cannot be targeted repeatedly")
	p2.set_physics_process(true)
	var before := p2.position
	await frames(35)
	check((p2.position - before).dot(frame.basis.x) > 0.15, "distracted player physically steers toward the off-track bone")
	race.resume_state = race.RaceState.RACING
	race.state = race.RaceState.PAUSED
	paused = true
	var remaining: float = p2.distraction_time
	var respawn: float = items.pickups[0].wait
	await frames(12)
	check(p2.distraction_time == remaining and items.pickups[0].wait == respawn, "pause freezes chase and pickup timers")
	race.resume()
	await frames(30)
	check(p2.distraction_time == 0 and p2.bone_immunity > 0, "control returns after one second with protection remaining")
	p2.set_physics_process(false)
	p1.global_position = Vector3(500, 0, 500)
	items._physics_process(11)
	check(items.pickups[0].wait == 0 and items.pickups[0].node.visible, "collected bone respawns")
	p1.reset_to(frame)
	p2.reset_to(side)
	p1.has_bone = true
	check(p1.try_throw(), "new throw succeeds after recovery clears old effect")
	p2.reset_to(side)
	items._physics_process(0.56)
	check(p2.distraction_time == 0, "an in-flight bone cannot affect a recovered target")
	p1.has_bone = true
	p2.has_bone = true
	race.restart()
	check(not p1.has_bone and not p2.has_bone and items.flights.is_empty(), "restart clears both inventories and projectiles")
	check(p2.distraction_time == 0 and not p2.bone_pending, "restart clears pending and active distractions")
	race.state = race.RaceState.RACING
	var npc: CharacterBody3D = race.rivals[0]
	var roadside := track.frame_at(0.35)
	roadside.origin += roadside.basis.x * (track.half_width + 8)
	roadside.origin.y = track.ground_height(roadside.origin)
	npc.reset_to(roadside)
	npc.stuck_time = 3.95
	var recoveries: int = npc.recovery_count
	npc.distract(roadside.origin - roadside.basis.z * 5)
	npc.set_physics_process(true)
	await frames(10)
	check(npc.distraction_time > 0.7 and npc.recovery_count == recoveries, "NPC stuck recovery cannot cancel an active bone chase")
	scene.queue_free()
	await process_frame
	print("ITEM RESULT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
