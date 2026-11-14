class_name CityDecor
extends RefCounted
static func build(track: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 836
	var stone := AlpineArt.material(Color("#ded0b9"))
	var glass := AlpineArt.material(Color("#385e72"), 0.18)
	glass.metallic = 0.35
	var light := AlpineArt.material(Color("#f9daa0"))
	var trim := AlpineArt.material(Color("#e9e4d8"))
	var dark := AlpineArt.material(Color("#263846"))
	var red := AlpineArt.material(Color("#c65d4c"))
	# Blocks line the outside of the circuit, leaving both cuts usable.
	for i in range(38):
		var frame: Transform3D = track.frame_at(float(i) / 38.0)
		var side := -1.0 if i % 2 else 1.0
		var pos := frame.origin + frame.basis.x * side * rng.randf_range(30, 42)
		if track.nearest(pos).distance < track.half_width + 18:
			continue
		pos.y = track.ground_height(pos)
		var building := Node3D.new()
		track.add_child(building)
		building.position = pos
		building.rotation.y = frame.basis.get_euler().y
		var height := rng.randf_range(12, 28)
		var width := rng.randf_range(9, 14)
		var facade := AlpineArt.material([Color("#b67f69"), Color("#b9b1a3"), Color("#8a9caa"), Color("#d6b995")][i % 4])
		AlpineArt.add_grain(facade)
		facade.uv1_scale = Vector3(6, 12, 6)
		AlpineArt.box(building, Vector3(0, height * 0.5, 0), Vector3(width, height, 11), facade)
		AlpineArt.box(building, Vector3(0, height, 0), Vector3(width + 0.5, 0.45, 11.5), trim)
		AlpineArt.box(building, Vector3(0, height + 1, 0), Vector3(3, 2, 3), dark)
		# Batch the many windows into one draw per building.
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		var window := BoxMesh.new()
		window.size = Vector3(1.25, 1.7, 0.09)
		window.material = glass
		multimesh.mesh = window
		var floors := int(height / 3.2)
		multimesh.instance_count = floors * 4 * 2
		var count := 0
		for floor_index in range(floors):
			for column in range(4):
				for face: float in [-1, 1]:
					multimesh.set_instance_transform(count, Transform3D(Basis.IDENTITY, Vector3((column - 1.5) * 2.15, floor_index * 3.2 + 2.5, face * 5.55)))
					count += 1
		var windows := MultiMeshInstance3D.new()
		windows.multimesh = multimesh
		building.add_child(windows)
		for face: float in [-1, 1]:
			AlpineArt.box(building, Vector3(0, 1.3, face * 5.62), Vector3(1.8, 2.6, 0.12), glass)
			AlpineArt.box(building, Vector3(0, 3.1, face * 6.1), Vector3(5, 0.3, 1.5), red if i % 2 else stone)
			AlpineArt.box(building, Vector3(0, 3.75, face * 5.65), Vector3(4.5, 0.65, 0.15), dark)
	# Lamps, bollards and road markings follow the actual hills.
	for i in range(44):
		var frame: Transform3D = track.frame_at(float(i) / 44)
		for side: float in [-1, 1]:
			var lamp := Node3D.new()
			track.add_child(lamp)
			lamp.transform = frame
			var x: float = side * (track.half_width + 7.4)
			AlpineArt.cone(lamp, Vector3(x, 3.7, 0), 0.11, 7.4, dark, 0.09)
			AlpineArt.beam(lamp, Vector3(x, 7.3, 0), Vector3(x - side * 1.8, 7.3, 0), 0.14, dark)
			AlpineArt.ellipsoid(lamp, Vector3(x - side * 1.8, 7.2, 0), Vector3(1.4, 0.25, 0.7), light)
			AlpineArt.cone(lamp, Vector3(x, 0.3, 0), 0.3, 0.6, stone, 0.2)
		var dash := AlpineArt.box(track, frame.origin + Vector3.UP * 0.025, Vector3(0.16, 0.018, 2.7), light)
		dash.basis = frame.basis
	for progress: float in [0.08, 0.39, 0.7]:
		var crossing := Node3D.new()
		track.add_child(crossing)
		crossing.transform = track.frame_at(progress)
		for i in range(8):
			AlpineArt.box(crossing, Vector3(0, 0.03, (i - 3.5) * 0.7), Vector3(track.half_width * 2, 0.02, 0.35), trim)
	# A clock tower provides a recognizable skyline landmark.
	var tower := Node3D.new()
	track.add_child(tower)
	tower.position = Vector3(0, -3.5, 0)
	AlpineArt.box(tower, Vector3(0, 15, 0), Vector3(10, 30, 10), stone)
	AlpineArt.box(tower, Vector3(0, 30, 0), Vector3(12, 1.5, 12), trim)
	AlpineArt.cone(tower, Vector3(0, 35, 0), 8, 10, dark)
	for face: float in [-1, 1]:
		AlpineArt.ellipsoid(tower, Vector3(0, 25, face * 5.1), Vector3(5, 5, 0.1), light)
		AlpineArt.beam(tower, Vector3(0, 25, face * 5.2), Vector3(0, 26.7, face * 5.2), 0.13, dark)
		AlpineArt.beam(tower, Vector3(0, 25, face * 5.2), Vector3(1.4, 24.4, face * 5.2), 0.13, dark)
