extends SceneTree
var failures := 0
var checks := 0
func _initialize() -> void:
	call_deferred("_run")
func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + text)
	else:
		print("PASS: " + text)
func frames(n: int) -> void:
	for i in range(n):
		await physics_frame
func _run() -> void:
	var state: Node = root.get_node("GameState")
	state.practice_run = true
	state.race_mode = 0
	state.course = 0
	state.difficulty = 1
	var scene: Node3D = load("res://scenes/main/Main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await frames(10)
	var race: Node = scene.get_node("RaceManager")
	var track: AlpineTrack = scene.get_node("Track")
	race.start()
	race.countdown = 0.01
	await frames(2)
	for original in get_nodes_in_group("racers"):
		original.set_physics_process(false)
		original.collision_layer = 0
		original.position = Vector3(500, 0, 500)
	var packed: PackedScene = load("res://scenes/vehicles/Sled.tscn")
	var a: CharacterBody3D = packed.instantiate()
	var b: CharacterBody3D = packed.instantiate()
	a.is_player = false
	b.is_player = false
	a.name = "ContactA"
	b.name = "ContactB"
	scene.add_child(a)
	scene.add_child(b)
	await frames(2)
	var frame := track.frame_at(0.12)
	var forward := -frame.basis.z
	var right := frame.basis.x
	a.reset_to(frame)
	var ahead := frame
	ahead.origin += forward * 9
	b.reset_to(ahead)
	b.rotation.y += PI
	await frames(20)
	a.current_speed = 20
	b.current_speed = 20
	a.drive_velocity = forward * 20
	b.drive_velocity = -forward * 20
	var hit := false
	var reversed := false
	for tick in range(90):
		await physics_frame
		if a.bump_count > 0:
			hit = true
			reversed = a.contact_velocity.dot(forward) < 0 and b.contact_velocity.dot(forward) > 0
			break
	check(hit, "swept physical sled collision is detected")
	check(a.bump_count == 1 and b.bump_count == 1, "one hit is resolved once for both racers")
	check(reversed, "head-on impact bounces both sleds backward")
	check(a.impact_velocity.dot(b.impact_velocity) < 0, "both teams receive opposite impulses")
	await frames(5)
	check(a.position.distance_to(b.position) > 3, "sleds separate instead of sticking")
	a.impact_velocity = Vector3(3, 0, 0)
	a.reset_to(frame)
	check(a.impact_velocity.is_zero_approx(), "reset clears contact momentum")
	scene.queue_free()
	await process_frame
	print("CONTACT RESULT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
