extends Node3D
## Small animated spectators and detailed roadside landmarks, outside the racing line.
var characters: Array[Dictionary] = []
var elapsed := 0.0

func build(track: Node3D, theme: int) -> void:
	for i in range(8):
		var frame: Transform3D = track.frame_at(0.045 + i * 0.119)
		var side := -1.0 if i % 2 else 1.0
		var pos: Vector3 = frame.origin + frame.basis.x * side * (track.half_width + 10 + (i % 3) * 2)
		if track.nearest(pos).distance < track.half_width + 8:
			continue
		pos.y = track.ground_height(pos)
		var prop := Node3D.new()
		add_child(prop)
		prop.position = pos
		prop.rotation.y = frame.basis.get_euler().y + side * PI * 0.4
		match theme:
			0: _bear(prop, i)
			1: _lemur(prop, i)
			2: _sweet(prop, i)
			3: _bus(prop, i)

func _bear(parent: Node3D, index: int) -> void:
	parent.name = "PolarBear%d" % index
	var fur := AlpineArt.material(Color("#d9d5cb"))
	var dark := AlpineArt.material(Color("#233743"))
	parent.scale = Vector3.ONE * (1.3 if index % 3 else 0.85)
	AlpineArt.ellipsoid(parent, Vector3(0, 1.3, 0.2), Vector3(1.6, 1.65, 2.8), fur)
	for x: float in [-0.55, 0.55]:
		for z: float in [-0.6, 0.95]:
			AlpineArt.ellipsoid(parent, Vector3(x, 0.6, z), Vector3(0.52, 1.25, 0.6), fur)
			AlpineArt.ellipsoid(parent, Vector3(x, 0.16, z - 0.16), Vector3(0.6, 0.3, 0.85), fur)
	var head := Node3D.new()
	parent.add_child(head)
	head.position = Vector3(0, 1.65, -1.1)
	AlpineArt.ellipsoid(head, Vector3.ZERO, Vector3(1.1, 1, 1.2), fur)
	AlpineArt.ellipsoid(head, Vector3(0, -0.15, -0.65), Vector3(0.65, 0.45, 0.8), fur)
	AlpineArt.ellipsoid(head, Vector3(0, -0.04, -1.02), Vector3(0.3, 0.2, 0.2), dark)
	for x: float in [-0.39, 0.39]:
		AlpineArt.ellipsoid(head, Vector3(x, 0.45, 0), Vector3.ONE * 0.36, fur)
		AlpineArt.ellipsoid(head, Vector3(x * 0.8, 0.1, -0.5), Vector3.ONE * 0.1, dark)
	characters.append({"part": head, "phase": float(index), "tail": false})

func _lemur(parent: Node3D, index: int) -> void:
	parent.name = "Lemur%d" % index
	var gray := AlpineArt.material(Color("#8c8a85"))
	var cream := AlpineArt.material(Color("#e9e0c9"))
	var dark := AlpineArt.material(Color("#333b3d"))
	var amber := AlpineArt.material(Color("#f0b743"))
	var rock := AlpineArt.material(Color("#697c60"))
	AlpineArt.ellipsoid(parent, Vector3(0, 0.2, 0), Vector3(3.2, 1.8, 2.8), rock)
	AlpineArt.ellipsoid(parent, Vector3(0, 1.5, 0), Vector3(0.9, 1.5, 0.8), gray)
	var head := Node3D.new()
	parent.add_child(head)
	head.position = Vector3(0, 2.3, -0.15)
	AlpineArt.ellipsoid(head, Vector3.ZERO, Vector3(0.85, 0.8, 0.75), cream)
	for x: float in [-0.22, 0.22]:
		AlpineArt.ellipsoid(head, Vector3(x, 0.02, -0.33), Vector3(0.3, 0.35, 0.12), dark)
		AlpineArt.ellipsoid(head, Vector3(x, 0.04, -0.41), Vector3.ONE * 0.12, amber)
		AlpineArt.cone(head, Vector3(x * 1.6, 0.4, 0), 0.18, 0.4, cream)
		AlpineArt.ellipsoid(parent, Vector3(x * 2, 1.1, -0.2), Vector3(0.24, 1.1, 0.3), dark)
	AlpineArt.ellipsoid(head, Vector3(0, -0.16, -0.44), Vector3(0.23, 0.17, 0.2), dark)
	var tail := Node3D.new()
	parent.add_child(tail)
	tail.position = Vector3(0, 1.1, 0.35)
	for segment in range(14):
		var t := segment / 13.0
		AlpineArt.ellipsoid(tail, Vector3(sin(t * PI * 0.8) * 0.5, t * 2.5, t * 0.7), Vector3(0.32, 0.32, 0.32), dark if segment % 2 else cream)
	characters.append({"part": tail, "phase": float(index), "tail": true})
	characters.append({"part": head, "phase": float(index), "tail": false})

func _sweet(parent: Node3D, index: int) -> void:
	parent.name = "Lollipop%d" % index
	var cream := AlpineArt.material(Color("#fff2ce"), 0.4)
	var candy := AlpineArt.material([Color("#e75c93"), Color("#7ac4ca"), Color("#a390dc")][index % 3], 0.22)
	AlpineArt.cone(parent, Vector3(0, 3, 0), 0.16, 6, cream, 0.16)
	AlpineArt.ellipsoid(parent, Vector3(0, 6, 0), Vector3(4.5, 4.5, 0.65), candy)
	# A real spiral with rounded segments instead of a single polygonal ring.
	var previous := Vector3(0, 6, -0.36)
	for segment in range(1, 90):
		var t := segment / 89.0
		var angle := t * TAU * 2.3
		var point := Vector3(cos(angle) * t * 1.95, 6 + sin(angle) * t * 1.95, -0.39)
		AlpineArt.beam(parent, previous, point, 0.13, cream)
		previous = point
	for x: float in [-1.5, 1.5]:
		AlpineArt.ellipsoid(parent, Vector3(x, 0.6, 0), Vector3(1.5, 1.6, 1.5), candy)

func _bus(parent: Node3D, index: int) -> void:
	parent.name = "CityBus%d" % index
	var paint := AlpineArt.material(Color("#db9953") if index % 2 == 0 else Color("#62a8ac"), 0.4)
	var glass := AlpineArt.material(Color("#244658"), 0.16)
	var dark := AlpineArt.material(Color("#273039"))
	var cream := AlpineArt.material(Color("#f6e5b9"))
	AlpineArt.box(parent, Vector3(0, 1.8, 0), Vector3(2.8, 2.8, 7), paint)
	AlpineArt.box(parent, Vector3(0, 3.25, 0), Vector3(2.85, 0.18, 7.05), cream)
	AlpineArt.box(parent, Vector3(0, 1.0, 0), Vector3(2.85, 0.18, 7.05), cream)
	for side: float in [-1, 1]:
		for z: float in [-2.4, -1.1, 0.2, 1.5, 2.8]:
			AlpineArt.box(parent, Vector3(side * 1.41, 2.35, z), Vector3(0.04, 1.0, 1.05), glass)
		for z: float in [-2.1, 2.1]:
			var wheel := AlpineArt.cone(parent, Vector3(side * 1.35, 0.65, z), 0.65, 0.25, dark, 0.65)
			wheel.rotation.z = PI / 2
			var hub := AlpineArt.cone(parent, Vector3(side * 1.5, 0.65, z), 0.26, 0.04, cream, 0.26)
			hub.rotation.z = PI / 2
		AlpineArt.box(parent, Vector3(side * 0.9, 1.15, -3.55), Vector3(0.45, 0.3, 0.08), cream)
	AlpineArt.box(parent, Vector3(0, 2.25, -3.53), Vector3(2.3, 1.2, 0.08), glass)
	var label := Label3D.new()
	parent.add_child(label)
	label.position = Vector3(0, 3, -3.56)
	label.rotation.y = PI
	label.text = "07  DOG PARK"
	label.font_size = 32
	label.pixel_size = 0.006
	label.modulate = Color("#ffe6a4")

func _process(delta: float) -> void:
	elapsed += delta
	for actor in characters:
		actor.part.rotation.y = sin(elapsed * 0.8 + actor.phase) * (0.3 if actor.tail else 0.18)
		if actor.tail:
			actor.part.rotation.z = sin(elapsed * 1.2 + actor.phase) * 0.14
