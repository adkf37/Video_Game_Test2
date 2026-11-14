class_name AlpineTrack
extends Node3D
## Four themed spline courses; road width follows the selected difficulty.
const SAMPLES := 320
var half_width := 8.0
var theme := 0
var course_name := "Alpine Valley"
var points := PackedVector3Array()
var lengths := PackedFloat32Array()
var total_length := 0.0
var rng := RandomNumberGenerator.new()
var snow := AlpineArt.material(Color("#e6f3f4"))
var trail := AlpineArt.material(Color("#6394a2"))
var bank := AlpineArt.material(Color("#afccd8"))
var pine := AlpineArt.material(Color("#245859"))
var pine_light := AlpineArt.material(Color("#397575"))
var wood := AlpineArt.material(Color("#684f49"))
var coral := AlpineArt.material(Color("#eb795d"))
var navy := AlpineArt.material(Color("#244759"))

func _ready() -> void:
	var settings: Node = get_tree().root.get_node("GameState")
	theme = settings.course
	half_width = RaceCatalog.WIDTHS[settings.difficulty]
	course_name = RaceCatalog.COURSES[theme]
	if theme == 1:
		snow = AlpineArt.material(Color("#527441"))
		trail = AlpineArt.material(Color("#987c54"))
		bank = AlpineArt.material(Color("#779156"))
	elif theme == 2:
		snow = AlpineArt.material(Color("#f5d7e4"))
		trail = AlpineArt.material(Color("#caa3c2"))
		bank = AlpineArt.material(Color("#fff0cf"))
	elif theme == 3:
		snow = AlpineArt.material(Color("#9aa5ad"))
		trail = AlpineArt.material(Color("#455665"))
		bank = AlpineArt.material(Color("#b7a79a"))
	for mat in [snow, trail, bank, wood, pine]:
		AlpineArt.add_grain(mat)
	rng.seed = 2048
	_build_path()
	_build_ribbon()
	_build_scenery()
	_build_start()
	var life := Node3D.new()
	life.name = "TrackLife"
	life.set_script(preload("res://scripts/track/TrackLife.gd"))
	add_child(life)
	life.build(self, theme)
	call_deferred("_apply_environment")

func _build_path() -> void:
	var anchors: Array[Vector3] = [
		Vector3(0, 0, 68), Vector3(-40, 0, 67), Vector3(-78, 1, 47),
		Vector3(-90, 3, 5), Vector3(-73, 5, -32), Vector3(-43, 6, -64),
		Vector3(-5, 5, -72), Vector3(29, 2, -52), Vector3(62, 1, -58),
		Vector3(91, 2, -28), Vector3(85, 4, 8), Vector3(58, 3, 23),
		Vector3(55, 1, 55), Vector3(30, 0, 73)]
	if theme == 1:
		anchors = [Vector3(0, 0, 75), Vector3(-45, 1, 72), Vector3(-92, 3, 45), Vector3(-108, 5, 2), Vector3(-88, 6, -43), Vector3(-42, 2, -61), Vector3(-2, 0, -48), Vector3(35, 1, -70), Vector3(82, 3, -62), Vector3(108, 5, -16), Vector3(91, 2, 28), Vector3(52, 0, 57)]
	elif theme == 2:
		anchors = [Vector3(0, 0, 80), Vector3(-50, 0, 80), Vector3(-88, 3, 48), Vector3(-83, 6, 2), Vector3(-105, 3, -36), Vector3(-75, 0, -78), Vector3(-22, 2, -82), Vector3(20, 5, -62), Vector3(70, 2, -82), Vector3(108, 0, -42), Vector3(88, 4, 0), Vector3(100, 3, 42), Vector3(55, 0, 77)]
	elif theme == 3:
		anchors = [Vector3(0, 0, 86), Vector3(-56, 1, 86), Vector3(-104, 3, 54), Vector3(-108, 7, 0), Vector3(-90, 5, -51), Vector3(-42, 2, -86), Vector3(6, 0, -83), Vector3(47, 3, -65), Vector3(101, 6, -52), Vector3(115, 4, -3), Vector3(83, 2, 40), Vector3(46, 0, 78)]
	for i in range(SAMPLES):
		var t := float(i) / SAMPLES * anchors.size()
		var j := int(t)
		var f := t - j
		var a := anchors[posmod(j - 1, anchors.size())]
		var b := anchors[j % anchors.size()]
		var c := anchors[(j + 1) % anchors.size()]
		var d := anchors[(j + 2) % anchors.size()]
		var point := 0.5 * ((2.0 * b) + (-a + c) * f + (2.0*a - 5.0*b + 4.0*c - d)*f*f + (-a + 3.0*b - 3.0*c + d)*f*f*f)
		# Broad climbs and descents, with a level start/finish apron.
		var phase := float(i) / SAMPLES * TAU
		point.y = point.y * 1.85 + (1.0 - cos(phase * 2.0)) * 1.5
		points.append(point)
	lengths.append(0.0)
	for i in range(SAMPLES):
		total_length += points[i].distance_to(points[(i + 1) % SAMPLES])
		lengths.append(total_length)

func frame_at(progress: float) -> Transform3D:
	var distance := fposmod(progress, 1.0) * total_length
	var index := 0
	while index < SAMPLES - 1 and lengths[index + 1] < distance:
		index += 1
	var fraction := (distance - lengths[index]) / (lengths[index + 1] - lengths[index])
	var a := points[index]
	var b := points[(index + 1) % SAMPLES]
	var forward := (b - a).normalized()
	return Transform3D(Basis.looking_at(forward, Vector3.UP), a.lerp(b, fraction))

func nearest(position_world: Vector3) -> Dictionary:
	var closest := INF
	var result := 0
	var fraction := 0.0
	var flat := Vector2(position_world.x, position_world.z)
	for i in range(SAMPLES):
		var a := Vector2(points[i].x, points[i].z)
		var b := Vector2(points[(i + 1) % SAMPLES].x, points[(i + 1) % SAMPLES].z)
		var f := clampf((flat - a).dot(b - a) / a.distance_squared_to(b), 0.0, 1.0)
		var distance := flat.distance_squared_to(a.lerp(b, f))
		if distance < closest:
			closest = distance
			result = i
			fraction = f
	return {"distance": sqrt(closest), "progress": lerpf(lengths[result], lengths[result + 1], fraction) / total_length}

func _vertex(index: int, offset: float, rise: float) -> Vector3:
	var point := points[index % SAMPLES]
	var forward := (points[(index + 1) % SAMPLES] - points[posmod(index - 1, SAMPLES)]).normalized()
	var right := forward.cross(Vector3.UP).normalized()
	return point + right * offset + Vector3.UP * rise

func _build_ribbon() -> void:
	# The flat six-metre first cut gives space to save a slide; deeper terrain tapers away.
	var widths := [-40.0, -half_width - 14, -half_width - 6, -half_width, half_width, half_width + 6, half_width + 14, 40.0]
	var heights := [-3.2, -0.4, 0.1, 0.0, 0.0, 0.1, -0.4, -3.2]
	var road_mesh := ArrayMesh.new()
	for strip in range(widths.size() - 1):
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in range(SAMPLES):
			var a := _vertex(i, widths[strip], heights[strip])
			var b := _vertex(i + 1, widths[strip], heights[strip])
			var c := _vertex(i + 1, widths[strip + 1], heights[strip + 1])
			var d := _vertex(i, widths[strip + 1], heights[strip + 1])
			for vertex: Vector3 in [a, b, c, a, c, d]:
				surface.set_uv(Vector2(vertex.x, vertex.z) * 0.18)
				surface.add_vertex(vertex)
		surface.index()
		surface.generate_normals()
		surface.set_material(trail if strip == 3 else (bank if strip == 2 or strip == 4 else snow))
		surface.commit(road_mesh)
	var road := MeshInstance3D.new()
	road.mesh = road_mesh
	add_child(road)
	road.create_trimesh_collision()
	var floor_body := StaticBody3D.new()
	add_child(floor_body)
	AlpineArt.box(floor_body, Vector3(0, -4, 0), Vector3(850, 1, 850), snow)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(850, 1, 850)
	shape.shape = box
	floor_body.add_child(shape)
	shape.position.y = -4

func _build_scenery() -> void:
	if theme == 3:
		CityDecor.build(self)
		return
	if theme > 0:
		BiomeDecor.build(self, theme)
		return
	for i in range(260):
		var frame := frame_at(rng.randf())
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		var pos := frame.origin + frame.basis.x * rng.randf_range(17.0, 65.0) * side
		if nearest(pos).distance < 14.0:
			continue
		pos.y = ground_height(pos)
		_tree(pos, rng.randf_range(0.7, 1.5))
	for i in range(32):
		var angle := TAU * i / 32.0
		var pos := Vector3(cos(angle) * rng.randf_range(205, 290), -5, sin(angle) * rng.randf_range(200, 280))
		var height := rng.randf_range(38, 95)
		var rock := AlpineArt.material(Color("#7397ab").lerp(Color("#b6c8d8"), rng.randf()))
		AlpineArt.ellipsoid(self, pos, Vector3(rng.randf_range(65, 100), height * 2, rng.randf_range(65, 100)), rock)
		AlpineArt.ellipsoid(self, pos + Vector3.UP * height * 0.7, Vector3(height * 0.48, height * 0.65, height * 0.48), snow)
	for i in range(50):
		var frame := frame_at(rng.randf())
		var pos := frame.origin + frame.basis.x * rng.randf_range(12, 24) * (-1 if i % 2 == 0 else 1)
		if nearest(pos).distance < 11:
			continue
		var rock := AlpineArt.ellipsoid(self, pos, Vector3(3.5, 2, 3) * rng.randf_range(0.5, 1.5), bank)
		rock.rotation.y = rng.randf() * TAU
	# A frozen tarn in the central clearing.
	var ice := AlpineArt.material(Color("#81bfc9"), 0.25)
	AlpineArt.ellipsoid(self, Vector3(0, -3.35, -4), Vector3(65, 0.25, 58), ice)
	for i in range(12):
		var frame := frame_at(float(i) / 12.0 + 0.025)
		for side: float in [-1.0, 1.0]:
			var pos := frame.origin + frame.basis.x * (half_width + 0.6) * side
			AlpineArt.cone(self, pos + Vector3.UP, 0.09, 2.0, wood, 0.09)
			var flag := AlpineArt.box(self, pos + Vector3.UP * 1.65, Vector3(0.8, 0.4, 0.04), coral)
			flag.rotation.y = frame.basis.get_euler().y
	_cabin(Vector3(24, 0, 91), -0.2)
	_cabin(Vector3(-6, -1, 101), 0.2)
	# Wayfinding signs before the tighter sections.
	for progress: float in [0.23, 0.52, 0.73]:
		var frame := frame_at(progress)
		var sign_node := Node3D.new()
		add_child(sign_node)
		sign_node.transform = frame
		AlpineArt.box(sign_node, Vector3(-10.0, 1.4, 0), Vector3(0.18, 2.8, 0.18), wood)
		AlpineArt.box(sign_node, Vector3(-10.0, 2.7, 0), Vector3(2.5, 1.0, 0.15), navy)
		var label := Label3D.new()
		sign_node.add_child(label)
		label.position = Vector3(-10.0, 2.7, 0.1)
		label.text = "SLOW"
		label.font_size = 52
		label.pixel_size = 0.012
		label.modulate = Color("#fff0bd")

func _tree(pos: Vector3, scale_value: float) -> void:
	var tree := Node3D.new()
	add_child(tree)
	tree.position = pos
	tree.scale = Vector3.ONE * scale_value
	AlpineArt.cone(tree, Vector3(0, 1.6, 0), 0.25, 3.2, wood, 0.18)
	for layer in range(3):
		var radius := 2.8 - layer * 0.65
		var y := 3.0 + layer * 1.65
		AlpineArt.cone(tree, Vector3(0, y, 0), radius, 3.8 - layer * 0.4, pine if layer % 2 == 0 else pine_light)
		AlpineArt.cone(tree, Vector3(0, y + 0.65, 0), radius * 0.82, 2.6 - layer * 0.25, snow)

func _cabin(pos: Vector3, angle: float) -> void:
	var cabin := Node3D.new()
	add_child(cabin)
	cabin.position = pos
	cabin.rotation.y = angle
	AlpineArt.box(cabin, Vector3(0, 2.2, 0), Vector3(9, 4.4, 7), wood)
	var roof := AlpineArt.box(cabin, Vector3(-2.6, 5.1, 0), Vector3(6, 0.5, 8.7), snow)
	roof.rotation.z = 0.42
	roof = AlpineArt.box(cabin, Vector3(2.6, 5.1, 0), Vector3(6, 0.5, 8.7), snow)
	roof.rotation.z = -0.42
	var glow := AlpineArt.material(Color("#ffd999"))
	glow.emission_enabled = true
	glow.emission = Color("#ffbd65")
	for x: float in [-2.5, 2.5]:
		AlpineArt.box(cabin, Vector3(x, 2.3, -3.52), Vector3(1.6, 1.6, 0.08), glow)
	AlpineArt.box(cabin, Vector3(0, 1.3, -3.55), Vector3(1.5, 2.6, 0.1), navy)
	AlpineArt.box(cabin, Vector3(2.5, 6, 1), Vector3(1.1, 3, 1.1), navy)

func _build_start() -> void:
	var start := Node3D.new()
	add_child(start)
	start.transform = frame_at(0.0)
	for x: float in [-half_width - 1.2, half_width + 1.2]:
		AlpineArt.box(start, Vector3(x, 5.0, 0), Vector3(0.45, 10, 0.45), wood)
		AlpineArt.box(start, Vector3(x, 9.6, 0), Vector3(0.8, 0.4, 0.8), coral)
	AlpineArt.box(start, Vector3(0, 9.0, 0), Vector3(half_width * 2 + 2.8, 1.4, 0.25), navy)
	var label := Label3D.new()
	start.add_child(label)
	label.position = Vector3(0, 9.0, 0.2)
	label.text = course_name.to_upper()
	label.font_size = 90
	label.pixel_size = 0.011
	label.modulate = Color("#fff6d9")
	for i in range(int(half_width * 2)):
		for row in range(2):
			AlpineArt.box(start, Vector3(-half_width + 0.5 + i, 0.025, row * 0.7 - 0.35), Vector3(1, 0.035, 0.7), navy if (i + row) % 2 == 0 else snow)

func _apply_environment() -> void:
	var world: WorldEnvironment = get_parent().get_node("WorldEnvironment")
	if theme == 0:
		return
	world.environment = world.environment.duplicate()
	# Solid themed skies avoid rebuilding radiance cubemaps on every garage reload.
	world.environment.sky = null
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	if theme == 1:
		world.environment.background_color = Color("#bed4a5")
		world.environment.fog_light_color = Color("#94b68b")
		world.environment.ambient_light_color = Color("#b9d3a4")
	elif theme == 2:
		world.environment.background_color = Color("#f5c4df")
		world.environment.fog_light_color = Color("#e2bbd9")
		world.environment.ambient_light_color = Color("#ddcbe4")
	elif theme == 3:
		world.environment.background_color = Color("#b9d4df")
		world.environment.fog_light_color = Color("#acbdcb")
		world.environment.ambient_light_color = Color("#c4d6e5")

func ground_height(pos: Vector3) -> float:
	var near_point := nearest(pos)
	var distance: float = near_point.distance
	if distance >= 40:
		return -3.5
	var y := frame_at(near_point.progress).origin.y
	if distance <= half_width:
		return y
	if distance <= half_width + 6:
		return y + inverse_lerp(half_width, half_width + 6, distance) * 0.1
	if distance <= half_width + 14:
		return y + lerpf(0.1, -0.4, inverse_lerp(half_width + 6, half_width + 14, distance))
	return y + lerpf(-0.4, -3.2, inverse_lerp(half_width + 14, 40, distance))
