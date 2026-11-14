class_name SledStyles
extends RefCounted
## Four distinct silhouettes and material families; common physics keeps choices fair.
static func build(parent: Node3D, style: int, accent: Material) -> void:
	var wood := AlpineArt.material(Color("#ae7652"))
	var metal := AlpineArt.material(Color("#78939e"), 0.25)
	metal.metallic = 0.8
	var dark := AlpineArt.material(Color("#182a32"), 0.3)
	var gold := AlpineArt.material(Color("#d9ab3d"), 0.2)
	gold.metallic = 0.75
	var chocolate := AlpineArt.material(Color("#512819"), 0.4)
	var cream := AlpineArt.material(Color("#fff0c4"))
	var frame: Material = wood
	if style == 1:
		frame = dark
	elif style == 2:
		frame = chocolate
	elif style == 3:
		frame = gold
	for side: float in [-1, 1]:
		AlpineArt.box(parent, Vector3(side * 0.68, 0.15, 0), Vector3(0.14, 0.12, 3.8), metal if style < 2 else frame)
		AlpineArt.beam(parent, Vector3(side * 0.68, 0.15, -1.9), Vector3(side * 0.68, 0.6, -2.15), 0.14, frame)
		AlpineArt.box(parent, Vector3(side * 0.65, 0.6, 0), Vector3(0.12, 0.65, 2.7), frame)
		AlpineArt.beam(parent, Vector3(side * 0.65, 0.6, 0.8), Vector3(side * 0.65, 1.65, 1.1), 0.1, frame)
	AlpineArt.box(parent, Vector3(0, 0.4, 0), Vector3(1.3, 0.18, 2.8), frame)
	AlpineArt.beam(parent, Vector3(-0.65, 1.65, 1.1), Vector3(0.65, 1.65, 1.1), 0.12, frame)
	match style:
		0:
			AlpineArt.ellipsoid(parent, Vector3(0, 0.7, -0.45), Vector3(1.15, 0.65, 1.7), accent)
			for z: float in [-1.0, -0.4, 0.2, 0.8]:
				AlpineArt.box(parent, Vector3(0, 0.47, z), Vector3(1.3, 0.08, 0.12), cream)
			AlpineArt.box(parent, Vector3(0, 0.94, -0.45), Vector3(0.1, 0.03, 1.6), cream)
		1:
			# Carbon composite tub, aluminum runners, aerodynamic nose and wing.
			AlpineArt.ellipsoid(parent, Vector3(0, 0.65, -0.7), Vector3(1.6, 0.7, 2.4), dark)
			AlpineArt.box(parent, Vector3(0, 0.99, -0.7), Vector3(0.24, 0.07, 2.1), accent)
			AlpineArt.box(parent, Vector3(0, 0.45, -1.9), Vector3(2.1, 0.15, 0.48), metal)
			for x: float in [-0.6, 0.6]:
				AlpineArt.box(parent, Vector3(x, 1.05, 1.3), Vector3(0.1, 0.9, 0.15), metal)
			AlpineArt.box(parent, Vector3(0, 1.5, 1.3), Vector3(2, 0.15, 0.5), accent)
		2:
			# A segmented chocolate bar with white-chocolate drizzle.
			for x: float in [-0.4, 0.4]:
				for z: float in [-1.15, -0.45, 0.25]:
					AlpineArt.box(parent, Vector3(x, 0.78, z), Vector3(0.72, 0.55, 0.62), chocolate)
			for z: float in [-1.0, -0.25, 0.5]:
				var drizzle := AlpineArt.box(parent, Vector3(0, 1.08, z), Vector3(1.45, 0.07, 0.1), cream)
				drizzle.rotation.y = -0.3
			for side: float in [-1, 1]:
				AlpineArt.ellipsoid(parent, Vector3(side * 0.8, 0.6, -1.3), Vector3(0.35, 0.35, 0.35), cream)
		3:
			# Forward driving platform keeps the musher in front of the throne.
			AlpineArt.box(parent, Vector3(0, 0.45, -1.55), Vector3(1.4, 0.15, 0.8), gold)
			AlpineArt.beam(parent, Vector3(-0.65, 1.5, -1.9), Vector3(0.65, 1.5, -1.9), 0.1, gold)
			var velvet := AlpineArt.material(Color("#752945"))
			AlpineArt.box(parent, Vector3(0, 0.82, -0.35), Vector3(1.6, 0.65, 1.8), gold)
			AlpineArt.box(parent, Vector3(0, 1.2, -0.35), Vector3(1.25, 0.22, 1.5), velvet)
			AlpineArt.box(parent, Vector3(0, 1.9, 0.45), Vector3(1.6, 2.3, 0.22), gold)
			AlpineArt.box(parent, Vector3(0, 1.95, 0.29), Vector3(1.3, 1.8, 0.1), velvet)
			for x: float in [-0.65, 0, 0.65]:
				AlpineArt.cone(parent, Vector3(x, 3.2, 0.45), 0.18, 0.55, gold)
				AlpineArt.ellipsoid(parent, Vector3(x, 2.0, 0.15), Vector3.ONE * 0.18, cream)
