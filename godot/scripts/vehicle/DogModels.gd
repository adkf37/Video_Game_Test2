class_name DogModels
extends RefCounted
## Breed-specific anatomy in game-native geometry: ears, muzzle, coat and tail.
static var materials: Dictionary = {}

static func coat(color: String) -> StandardMaterial3D:
	if not materials.has(color):
		materials[color] = AlpineArt.material(Color(color), 0.78)
	return materials[color]

static func build(dog: Node3D, breed: int, index: int, harness: Material) -> Dictionary:
	var cream := coat("#f6ead6")
	var ink := coat("#201f24")
	var pink := coat("#cb8c83")
	var fur := coat(["#637682", "#c57e3d", "#b5a080", "#d4aa78"][breed])
	if breed == 0 and index % 3 == 1:
		fur = coat("#9b6949")
	elif breed == 3:
		fur = coat(["#d4aa78", "#f1d6ae", "#705044", "#ad774d"][index % 4])
	# Corgis have long barrels and short legs; mastiffs are deep-chested.
	# Chihuahuas have a fine build, an apple dome and a short, tapered muzzle.
	dog.scale = Vector3.ONE * [1.0, 0.85, 1.38, 0.62][breed]
	var body_size: Vector3 = [Vector3(0.7, 0.75, 1.35), Vector3(0.7, 0.61, 1.55), Vector3(0.88, 0.91, 1.4), Vector3(0.46, 0.47, 0.92)][breed]
	var body_y: float = [0.94, 0.64, 1.02, 0.69][breed]
	var head_pos: Vector3 = [Vector3(0, 1.31, -0.66), Vector3(0, 0.98, -0.8), Vector3(0, 1.35, -0.68), Vector3(0, 1.03, -0.47)][breed]
	var head_size: Vector3 = [Vector3(0.61, 0.64, 0.67), Vector3(0.65, 0.63, 0.66), Vector3(0.85, 0.74, 0.74), Vector3(0.58, 0.61, 0.53)][breed]
	AlpineArt.ellipsoid(dog, Vector3(0, body_y, 0.04), body_size, fur)
	AlpineArt.ellipsoid(dog, Vector3(0, body_y - 0.02, -body_size.z * 0.3), Vector3(body_size.x * 0.88, body_size.y * 0.95, 0.5), cream if breed < 2 else fur)
	AlpineArt.ellipsoid(dog, head_pos + Vector3(0, -0.17, 0.16), Vector3(head_size.x * 0.8, 0.58, 0.5), fur)
	var head := Node3D.new()
	head.name = "Head"
	dog.add_child(head)
	head.position = head_pos
	AlpineArt.ellipsoid(head, Vector3.ZERO, head_size, fur)
	var muzzle_size: Vector3 = [Vector3(0.36, 0.29, 0.47), Vector3(0.38, 0.28, 0.44), Vector3(0.64, 0.44, 0.42), Vector3(0.28, 0.22, 0.25)][breed]
	var muzzle_z: float = [-0.36, -0.36, -0.34, -0.28][breed]
	var muzzle_color := ink if breed == 2 else (cream if breed < 2 else fur)
	AlpineArt.ellipsoid(head, Vector3(0, -0.13, muzzle_z), muzzle_size, muzzle_color)
	if breed == 2:
		for side: float in [-1, 1]:
			AlpineArt.ellipsoid(head, Vector3(side * 0.21, -0.25, -0.35), Vector3(0.28, 0.27, 0.37), coat("#51453b"))
	else:
		AlpineArt.ellipsoid(head, Vector3(0, -0.21, muzzle_z), muzzle_size * Vector3(0.8, 0.35, 0.85), cream)
	AlpineArt.ellipsoid(head, Vector3(0, -0.07, muzzle_z - muzzle_size.z * 0.48), Vector3(0.17, 0.12, 0.12) * (1.35 if breed == 2 else 1.0), ink)
	for side: float in [-1, 1]:
		var eye_x := head_size.x * 0.32 * side
		var eye_z := -head_size.z * 0.41
		if breed == 0:
			var mask := AlpineArt.ellipsoid(head, Vector3(eye_x, 0.01, eye_z + 0.035), Vector3(0.25, 0.29, 0.13), cream)
			mask.rotation.z = side * 0.28
		var eye_size := 0.145 if breed == 3 else 0.105
		AlpineArt.ellipsoid(head, Vector3(eye_x, 0.04, eye_z - 0.02), Vector3(eye_size, eye_size * 1.1, eye_size * 0.65), ink)
		AlpineArt.ellipsoid(head, Vector3(eye_x - 0.02, 0.067, eye_z - eye_size * 0.36), Vector3.ONE * 0.029, cream)
		if breed == 2:
			var ear := AlpineArt.ellipsoid(head, Vector3(side * 0.42, -0.04, 0.06), Vector3(0.22, 0.6, 0.36), coat("#675545"))
			ear.rotation.z = -side * 0.15
		else:
			var ear := Node3D.new()
			head.add_child(ear)
			ear.position = Vector3(side * head_size.x * 0.32, head_size.y * 0.29, 0.025)
			ear.rotation.z = -side * (0.32 if breed == 3 else 0.13)
			var width: float = [0.25, 0.33, 0.0, 0.36][breed]
			var height: float = [0.38, 0.44, 0.0, 0.48][breed]
			_ear(ear, width, height, 0.12, fur)
			var inner := Node3D.new()
			ear.add_child(inner)
			inner.position = Vector3(0, height * 0.12, -0.068)
			_ear(inner, width * 0.61, height * 0.72, 0.022, pink)
	# Slimmer shins, rounded joints and separate paws give a running silhouette.
	var limbs: Array[Node3D] = []
	var hip_y := body_y - body_size.y * 0.2
	var leg_width: float = [0.16, 0.19, 0.24, 0.095][breed]
	for side: float in [-1, 1]:
		for z: float in [-body_size.z * 0.32, body_size.z * 0.32]:
			var pivot := Node3D.new()
			dog.add_child(pivot)
			pivot.position = Vector3(side * body_size.x * 0.35, hip_y, z)
			AlpineArt.ellipsoid(pivot, Vector3(0, -hip_y * 0.22, 0.025), Vector3(leg_width * 1.45, hip_y * 0.6, leg_width * 1.6), fur)
			AlpineArt.ellipsoid(pivot, Vector3(0, -hip_y * 0.65, 0), Vector3(leg_width, hip_y * 0.65, leg_width), cream if breed < 2 else fur)
			AlpineArt.ellipsoid(pivot, Vector3(0, -hip_y + 0.08, -0.05), Vector3(leg_width * 1.5, 0.15, leg_width * 2), cream if breed < 2 else fur)
			limbs.append(pivot)
	AlpineArt.ellipsoid(dog, Vector3(0, body_y + 0.04, -body_size.z * 0.22), Vector3(body_size.x * 1.03, body_size.y * 1.02, 0.13), harness)
	AlpineArt.beam(dog, Vector3(0, body_y + body_size.y * 0.5, -0.22), Vector3(0, body_y + body_size.y * 0.5, 0.38), 0.085, harness)
	var tail := Node3D.new()
	dog.add_child(tail)
	tail.position = Vector3(0, body_y + 0.12, body_size.z * 0.43)
	if breed == 1:
		AlpineArt.ellipsoid(tail, Vector3(0, 0.06, 0.08), Vector3.ONE * 0.25, cream)
	else:
		var previous := Vector3.ZERO
		for segment in range(1, 9):
			var t := segment / 8.0
			var pos := Vector3(0, sin(t * PI * 0.8) * (0.47 if breed != 2 else -0.25), t * (0.55 if breed != 2 else 0.7))
			var thick := lerpf(0.25 if breed == 0 else 0.12, 0.08 if breed == 0 else 0.035, t)
			var piece := AlpineArt.cone(tail, (previous + pos) * 0.5, thick * 0.55, previous.distance_to(pos) + 0.04, cream if breed == 0 else fur, thick * 0.48)
			piece.quaternion = Quaternion(Vector3.UP, (pos - previous).normalized())
			previous = pos

	return {"legs": limbs, "tail": tail, "head": head}

static func _ear(parent: Node3D, width: float, height: float, depth: float, mat: Material) -> void:
	# A rounded, flattened leaf, with a broad base and a tapered tip (not a cone).
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := 8
	var sides := 10
	for ring in range(rings):
		for side in range(sides):
			for corner: Vector2i in [Vector2i(0, 0), Vector2i(1, 1), Vector2i(1, 0), Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)]:
				var t := float(ring + corner.x) / rings
				var angle := float(side + corner.y) / sides * TAU
				var taper := maxf(0.015, pow(1.0 - t, 0.65) * (0.6 + sin(t * PI) * 0.55))
				surface.add_vertex(Vector3(cos(angle) * width * 0.5 * taper, t * height, sin(angle) * depth * 0.5 * taper))
	surface.index()
	surface.generate_normals()
	var mesh := surface.commit()
	var instance := AlpineArt.mesh(parent, mesh, Vector3.ZERO, mat)
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
