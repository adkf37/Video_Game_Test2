extends Node3D
## Small animated spectators and detailed roadside landmarks, outside the racing line.
var characters: Array[Dictionary] = []
var elapsed := 0.0
var motions: Array[Dictionary] = []

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
		_watch(prop, "bus" if theme == 3 else ("sway" if theme == 2 else "breathe"), i)
		if i % 2 == 0:
			var companion := Node3D.new()
			add_child(companion)
			var companion_pos := pos + frame.basis.z * 7 + frame.basis.x * side * 4
			companion_pos.y = track.ground_height(companion_pos)
			companion.position = companion_pos
			companion.rotation.y = prop.rotation.y
			match theme:
				0: _fox(companion, i)
				1: _toucan(companion, i)
				2: _gingerbread(companion, i)
				3: _pigeon(companion, i)

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
			_watch(wheel, "wheel", index)
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
	for motion in motions:
		var t: float = elapsed + motion.phase
		var part: Node3D = motion.part
		match motion.kind:
			"breathe":
				part.position.y = motion.position.y + sin(t * 1.8) * 0.08
				part.rotation.z = motion.rotation.z + sin(t * 0.8) * 0.035
			"sway": part.rotation.z = motion.rotation.z + sin(t * 1.2) * 0.065
			"peck": part.rotation.x = motion.rotation.x + sin(t * 1.7) * 0.2
			"wave": part.rotation.z = motion.rotation.z + sin(t * 2) * 0.3
			"flap": part.rotation.z = motion.rotation.z + sin(t * 2.5) * 0.5
			"bus": part.position = motion.position + part.basis.z * sin(t * 0.5) * 2.0
			"wheel": part.rotation.x = motion.rotation.x + sin(t * 0.5) * 3.1
	for actor in characters:
		actor.part.rotation.y = sin(elapsed * 0.8 + actor.phase) * (0.3 if actor.tail else 0.18)
		if actor.tail:
			actor.part.rotation.z = sin(elapsed * 1.2 + actor.phase) * 0.14

func _watch(part: Node3D, kind: String, index: int) -> void:
	motions.append({"part": part, "kind": kind, "phase": float(index), "position": part.position, "rotation": part.rotation})

func _fox(parent: Node3D, index: int) -> void:
	parent.name = "ArcticFox%d" % index
	var fur := AlpineArt.material(Color("#e8eef0"))
	var shadow := AlpineArt.material(Color("#b9cbd1"))
	var ink := AlpineArt.material(Color("#283a45"))
	AlpineArt.ellipsoid(parent, Vector3(0, 0.85, 0.1), Vector3(0.8, 0.85, 1.7), fur)
	for x: float in [-0.25, 0.25]:
		for z: float in [-0.4, 0.6]:
			AlpineArt.ellipsoid(parent, Vector3(x, 0.38, z), Vector3(0.25, 0.75, 0.3), fur)
	var head := Node3D.new()
	parent.add_child(head)
	head.position = Vector3(0, 1.15, -0.7)
	AlpineArt.ellipsoid(head, Vector3.ZERO, Vector3(0.73, 0.66, 0.65), fur)
	AlpineArt.ellipsoid(head, Vector3(0, -0.1, -0.4), Vector3(0.33, 0.28, 0.5), fur)
	AlpineArt.ellipsoid(head, Vector3(0, -0.04, -0.65), Vector3.ONE * 0.14, ink)
	for x: float in [-0.23, 0.23]:
		AlpineArt.cone(head, Vector3(x, 0.42, 0.02), 0.19, 0.45, fur)
		AlpineArt.ellipsoid(head, Vector3(x, 0.05, -0.28), Vector3(0.1, 0.07, 0.08), ink)
	var tail := Node3D.new()
	parent.add_child(tail)
	tail.position = Vector3(0, 0.9, 0.85)
	AlpineArt.ellipsoid(tail, Vector3(0, 0.06, 0.55), Vector3(0.55, 0.55, 1.35), shadow)
	AlpineArt.ellipsoid(tail, Vector3(0, 0.08, 1.02), Vector3(0.4, 0.43, 0.55), fur)
	_watch(parent, "breathe", index)
	_watch(head, "peck", index)
	_watch(tail, "wave", index)

func _toucan(parent: Node3D, index: int) -> void:
	parent.name = "Toucan%d" % index
	var black := AlpineArt.material(Color("#273942"))
	var yellow := AlpineArt.material(Color("#ffd15a"))
	var orange := AlpineArt.material(Color("#ed834b"))
	var cream := AlpineArt.material(Color("#fff4cb"))
	var wood := AlpineArt.material(Color("#7b6147"))
	AlpineArt.cone(parent, Vector3(0, 1, 0), 0.42, 2.0, wood, 0.3)
	AlpineArt.ellipsoid(parent, Vector3(0, 2.7, 0), Vector3(0.95, 1.4, 0.85), black)
	AlpineArt.ellipsoid(parent, Vector3(0, 2.83, -0.37), Vector3(0.65, 0.9, 0.25), cream)
	var head := Node3D.new()
	parent.add_child(head)
	head.position = Vector3(0, 3.45, -0.08)
	AlpineArt.ellipsoid(head, Vector3.ZERO, Vector3(0.85, 0.85, 0.8), black)
	AlpineArt.ellipsoid(head, Vector3(0, -0.04, -0.66), Vector3(0.48, 0.52, 1.16), yellow)
	AlpineArt.ellipsoid(head, Vector3(0, -0.08, -1.09), Vector3(0.33, 0.36, 0.42), orange)
	for side: float in [-1, 1]:
		AlpineArt.ellipsoid(head, Vector3(side * 0.35, 0.06, -0.22), Vector3.ONE * 0.16, cream)
		AlpineArt.ellipsoid(head, Vector3(side * 0.42, 0.07, -0.24), Vector3.ONE * 0.075, black)
		var wing := Node3D.new()
		parent.add_child(wing)
		wing.position = Vector3(side * 0.4, 3.0, 0)
		AlpineArt.ellipsoid(wing, Vector3(side * 0.35, -0.25, 0.1), Vector3(0.8, 0.3, 1.0), black)
		_watch(wing, "flap", index + (0 if side < 0 else 3))
	_watch(head, "peck", index)

func _gingerbread(parent: Node3D, index: int) -> void:
	parent.name = "Gingerbread%d" % index
	var biscuit := AlpineArt.material(Color("#b77945"))
	var icing := AlpineArt.material(Color("#fff2da"))
	var berry := AlpineArt.material(Color("#d85b74"))
	var dark := AlpineArt.material(Color("#57392f"))
	AlpineArt.ellipsoid(parent, Vector3(0, 1.35, 0), Vector3(1.3, 1.6, 0.48), biscuit)
	AlpineArt.ellipsoid(parent, Vector3(0, 2.55, 0), Vector3(1.35, 1.35, 0.48), biscuit)
	for x: float in [-0.43, 0.43]:
		AlpineArt.ellipsoid(parent, Vector3(x, 0.48, 0), Vector3(0.58, 1.0, 0.48), biscuit)
		AlpineArt.ellipsoid(parent, Vector3(x * 0.6, 2.67, -0.25), Vector3.ONE * 0.14, dark)
		var arm := Node3D.new()
		parent.add_child(arm)
		arm.position = Vector3(x * 1.4, 1.88, 0)
		AlpineArt.ellipsoid(arm, Vector3(signf(x) * 0.4, 0, 0), Vector3(1.15, 0.48, 0.48), biscuit)
		AlpineArt.ellipsoid(arm, Vector3(signf(x) * 0.55, 0, -0.19), Vector3(0.14, 0.4, 0.12), icing)
		_watch(arm, "wave", index + (0 if x < 0 else 2))
	for y: float in [1.0, 1.4, 1.8]:
		AlpineArt.ellipsoid(parent, Vector3(0, y, -0.26), Vector3.ONE * 0.2, berry)
	for segment in range(8):
		var a := float(segment) / 7 * PI
		AlpineArt.ellipsoid(parent, Vector3(cos(a) * 0.3, 2.4 - sin(a) * 0.16, -0.26), Vector3.ONE * 0.075, icing)
	_watch(parent, "breathe", index)

func _pigeon(parent: Node3D, index: int) -> void:
	parent.name = "Pigeon%d" % index
	parent.scale = Vector3.ONE * 1.8
	var gray := AlpineArt.material(Color("#8a9ba8"))
	var dark := AlpineArt.material(Color("#455965"))
	var neck := AlpineArt.material(Color("#4f8d82"), 0.4)
	var orange := AlpineArt.material(Color("#d89968"))
	AlpineArt.ellipsoid(parent, Vector3(0, 0.5, 0.1), Vector3(0.63, 0.72, 0.95), gray)
	for x: float in [-0.16, 0.16]:
		AlpineArt.beam(parent, Vector3(x, 0.25, 0), Vector3(x, 0.04, -0.12), 0.055, orange)
		AlpineArt.ellipsoid(parent, Vector3(signf(x) * 0.28, 0.51, 0.15), Vector3(0.16, 0.43, 0.76), dark)
	var head := Node3D.new()
	parent.add_child(head)
	head.position = Vector3(0, 0.92, -0.25)
	AlpineArt.ellipsoid(head, Vector3(0, -0.14, 0), Vector3(0.33, 0.55, 0.34), neck)
	AlpineArt.ellipsoid(head, Vector3.ZERO, Vector3.ONE * 0.4, gray)
	AlpineArt.ellipsoid(head, Vector3(0, -0.04, -0.27), Vector3(0.12, 0.1, 0.3), dark)
	for x: float in [-0.18, 0.18]:
		AlpineArt.ellipsoid(head, Vector3(x, 0.04, -0.06), Vector3.ONE * 0.075, orange)
	_watch(head, "peck", index)
	_watch(parent, "breathe", index)
