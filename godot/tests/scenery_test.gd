extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var settings: Node = root.get_node("GameState")
	settings.practice_run = true
	settings.race_mode = 0
	var names := ["ArcticFox", "Toucan", "Gingerbread", "Pigeon"]
	for course in range(4):
		settings.course = course
		var scene: Node3D = load("res://scenes/main/Main.tscn").instantiate()
		root.add_child(scene)
		current_scene = scene
		await process_frame
		await process_frame
		var life: Node3D = scene.get_node("Track/TrackLife")
		var found := false
		for prop in life.get_children():
			if str(prop.name).begins_with(names[course]):
				found = true
		if not found:
			failures += 1
			push_error("Missing new spectator on course %d" % course)
		var before: Array[Transform3D] = []
		for motion in life.motions:
			before.append(motion.part.transform)
		life._process(0.75)
		for i in range(before.size()):
			if before[i].is_equal_approx(life.motions[i].part.transform):
				failures += 1
		print("SCENERY ", course, " new=", found, " animated_parts=", before.size())
		var hud: Node = scene.get_node("HUD")
		if not hud.menu_controls_text().begins_with("SOLO RACE"):
			failures += 1
		scene.queue_free()
		await process_frame
	print("SCENERY RESULT: ", failures, " failures")
	quit(0 if failures == 0 else 1)
