class_name BiomeDecor
extends RefCounted
## Distinct scenery sets for the two additional courses.
static func build(track: Node3D, theme: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 450 + theme
	var green := AlpineArt.material(Color("#397440"))
	var leaf := AlpineArt.material(Color("#649b48"))
	var trunk := AlpineArt.material(Color("#765331"))
	var stone := AlpineArt.material(Color("#647e69"))
	var pink := AlpineArt.material(Color("#ee97ba"))
	var cream := AlpineArt.material(Color("#fff0d6"))
	var chocolate := AlpineArt.material(Color("#794a39"))
	var purple := AlpineArt.material(Color("#aa8bc4"))
	for i in range(150):
		var frame: Transform3D = track.frame_at(rng.randf())
		var distance := rng.randf_range(track.half_width + 7, 52)
		var pos: Vector3 = frame.origin + frame.basis.x * distance * (-1.0 if i % 2 == 0 else 1.0)
		if track.nearest(pos).distance < track.half_width + 5:
			continue
		pos.y = track.ground_height(pos)
		var prop := Node3D.new()
		track.add_child(prop)
		prop.position = pos
		prop.scale = Vector3.ONE * rng.randf_range(0.75, 1.35)
		if theme == 1:
			AlpineArt.cone(prop, Vector3(0, 4, 0), 0.5, 8, trunk, 0.25)
			for j in range(5):
				var angle := j * TAU / 5 + rng.randf_range(-0.2, 0.2)
				var frond := AlpineArt.ellipsoid(prop, Vector3(sin(angle) * 2.4, 7.6, cos(angle) * 2.4), Vector3(1.8, 0.45, 6.2), leaf if j % 2 == 0 else green)
				frond.rotation.y = angle
				frond.rotation.x = 0.17
			if i % 3 == 0:
				AlpineArt.ellipsoid(prop, Vector3(0, 6.8, 0), Vector3(7, 3, 6), green)
				for j in range(3):
					AlpineArt.beam(prop, Vector3(j - 1, 7, 0), Vector3(j - 0.5, 2, 0.6), 0.09, leaf)
		else:
			var sweet: Material = [pink, purple, cream][i % 3]
			if i % 3 == 0:
				AlpineArt.cone(prop, Vector3(0, 3.2, 0), 0.18, 6.4, cream, 0.18)
				AlpineArt.ellipsoid(prop, Vector3(0, 6.5, 0), Vector3(3.8, 3.8, 0.8), sweet)
				var swirl := TorusMesh.new()
				swirl.inner_radius = 0.7
				swirl.outer_radius = 1.3
				swirl.rings = 32
				swirl.ring_segments = 12
				var ring := AlpineArt.mesh(prop, swirl, Vector3(0, 6.5, 0.48), cream)
				ring.rotation.x = PI / 2
			elif i % 3 == 1:
				AlpineArt.ellipsoid(prop, Vector3(0, 1.8, 0), Vector3(4, 4.8, 4), sweet)
				for j in range(5):
					var sprinkle := AlpineArt.box(prop, Vector3(rng.randf_range(-1.4, 1.4), rng.randf_range(2, 3.7), -1.5), Vector3(0.15, 0.45, 0.12), cream)
					sprinkle.rotation.z = rng.randf()
			else:
				AlpineArt.cone(prop, Vector3(0, 2, 0), 1.6, 4, chocolate, 1.2)
				AlpineArt.ellipsoid(prop, Vector3(0, 4.1, 0), Vector3(4.2, 3, 4.2), sweet)
				AlpineArt.ellipsoid(prop, Vector3(0, 5.7, 0), Vector3.ONE * 0.7, pink)
	for i in range(18):
		var angle := TAU * i / 18
		var pos := Vector3(cos(angle) * 205, -4, sin(angle) * 195)
		var height := rng.randf_range(24, 55)
		AlpineArt.ellipsoid(track, pos, Vector3(65, height * 2, 60), green if theme == 1 else [pink, purple, cream][i % 3])
	var water := AlpineArt.material(Color("#439e9a") if theme == 1 else Color("#d67f9d"), 0.3)
	AlpineArt.ellipsoid(track, Vector3(0, -3.3, 0), Vector3(75, 0.3, 58), water)
	if theme == 1:
		# Stepped temple and a waterfall are visible landmarks on opposite bends.
		for level in range(5):
			AlpineArt.box(track, Vector3(5, level * 2.5 - 1, -100), Vector3(26 - level * 4, 3, 22 - level * 3), stone)
		AlpineArt.box(track, Vector3(5, 12, -100), Vector3(8, 5, 7), trunk)
		AlpineArt.box(track, Vector3(5, 11.5, -95.9), Vector3(3.3, 4.5, 0.3), green)
		AlpineArt.box(track, Vector3(120, 11, -35), Vector3(10, 30, 13), stone)
		AlpineArt.box(track, Vector3(113.9, 10, -35), Vector3(0.2, 25, 7), water)
		for j in range(3):
			AlpineArt.box(track, Vector3(113.7, 10, -37 + j * 2), Vector3(0.15, 25, 0.3), cream)
	else:
		# A frosted palace, with chocolate walls and gumdrop turrets.
		AlpineArt.box(track, Vector3(0, 4, -110), Vector3(30, 12, 12), pink)
		AlpineArt.box(track, Vector3(0, 4, -103.8), Vector3(6, 8, 0.3), chocolate)
		for x: float in [-16, -8, 8, 16]:
			AlpineArt.cone(track, Vector3(x, 7, -110), 3, 18, cream, 3)
			AlpineArt.cone(track, Vector3(x, 19, -110), 4, 7, purple if x < 0 else pink)
			AlpineArt.ellipsoid(track, Vector3(x, 23, -110), Vector3.ONE * 1.2, chocolate)
		for i in range(9):
			AlpineArt.box(track, Vector3(-14 + i * 3.5, 11, -110), Vector3(1.8, 2.5, 12), cream)
