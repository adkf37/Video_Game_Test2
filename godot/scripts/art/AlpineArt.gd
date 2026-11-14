class_name AlpineArt
extends RefCounted
## Original low-poly geometry shared by the trail and dog team.
static func material(color: Color, roughness: float = 0.9) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	return mat

static func mesh(parent: Node3D, shape: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
	var item := MeshInstance3D.new()
	item.mesh = shape
	item.material_override = mat
	parent.add_child(item)
	item.position = pos
	return item

static func box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = size
	return mesh(parent, shape, pos, mat)

static func ellipsoid(parent: Node3D, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var shape := SphereMesh.new()
	shape.radial_segments = 24
	shape.rings = 12
	shape.radius = 0.5
	shape.height = 1.0
	var item := mesh(parent, shape, pos, mat)
	item.scale = size
	return item

static func cone(parent: Node3D, pos: Vector3, radius: float, height: float, mat: Material, top: float = 0.0) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.top_radius = top
	shape.bottom_radius = radius
	shape.height = height
	shape.radial_segments = 20
	return mesh(parent, shape, pos, mat)

static func beam(parent: Node3D, from: Vector3, to: Vector3, thickness: float, mat: Material) -> MeshInstance3D:
	var item := box(parent, (from + to) * 0.5, Vector3(thickness, thickness, from.distance_to(to)), mat)
	var direction := (to - from).normalized()
	var up := Vector3.FORWARD if absf(direction.dot(Vector3.UP)) > 0.999 else Vector3.UP
	# Endpoints are local to the parent, including already-rotated moving sleds.
	item.basis = Basis.looking_at(direction, up)
	return item

static func add_grain(mat: StandardMaterial3D) -> void:
	var picture := Image.create(64, 64, false, Image.FORMAT_RGB8)
	var random := RandomNumberGenerator.new()
	random.seed = 1234
	for y in range(64):
		for x in range(64):
			var shade := random.randf_range(0.87, 1.0)
			picture.set_pixel(x, y, Color(shade, shade, shade))
	picture.generate_mipmaps()
	mat.albedo_texture = ImageTexture.create_from_image(picture)
