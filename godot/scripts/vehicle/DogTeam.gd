extends Node3D
## Breed-sized teams, four sled styles, and articulated running.
@export var team_color := Color("#e7684c")
var musher_layer := 1
var musher: Node3D
var breed := 0
var sled_style := 0
var dogs: Array[Node3D] = []
var legs: Array[Node3D] = []
var tails: Array[Node3D] = []
var phase := 0.0
var white := AlpineArt.material(Color("#f5eee1"))
var dark := AlpineArt.material(Color("#334859"))
var nose := AlpineArt.material(Color("#172c38"))
var coral := AlpineArt.material(Color("#e7684c"))
var timber := AlpineArt.material(Color("#ae7652"))
var steel := AlpineArt.material(Color("#6d919b"), 0.35)
var rope := AlpineArt.material(Color("#d1b48b"))
var spray: CPUParticles3D

func _ready() -> void:
	rebuild()

func rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	dogs.clear()
	legs.clear()
	tails.clear()
	phase = 0
	coral.albedo_color = team_color
	var rows: int = RaceCatalog.TEAM_COUNTS[breed] / 2
	var spacing: float = [2.45, 1.65, 3.0, 1.15][breed]
	var side_gap: float = [0.9, 0.65, 1.1, 0.5][breed]
	for row in range(rows):
		var z := -3.0 - row * spacing
		for side: float in [-1.0, 1.0]:
			_make_dog(Vector3(side * side_gap, 0, z), dogs.size())
			AlpineArt.beam(self, Vector3(0, 0.6, z + 0.6), Vector3(side * side_gap, 0.6, z), 0.03, rope)
	AlpineArt.beam(self, Vector3(0, 0.6, -0.8), Vector3(0, 0.6, -3.0 - (rows - 1) * spacing), 0.04, rope)
	SledStyles.build(self, sled_style, coral)
	musher = Node3D.new()
	musher.name = "Musher"
	add_child(musher)
	musher.position.z = -2.5 if sled_style == 3 else 0.0
	# A bundled-up musher gives the dog team a clear sense of scale.
	for side: float in [-1.0, 1.0]:
		AlpineArt.box(musher, Vector3(side * 0.24, 0.75, 1.15), Vector3(0.23, 0.85, 0.28), dark)
	AlpineArt.ellipsoid(musher, Vector3(0, 1.5, 1.1), Vector3(0.95, 1.1, 0.65), coral)
	AlpineArt.ellipsoid(musher, Vector3(0, 2.15, 1.0), Vector3(0.66, 0.66, 0.66), white)
	AlpineArt.ellipsoid(musher, Vector3(0, 2.35, 1.06), Vector3(0.7, 0.45, 0.7), dark)
	AlpineArt.ellipsoid(musher, Vector3(0, 2.62, 1.06), Vector3.ONE * 0.2, coral)
	for side: float in [-1.0, 1.0]:
		AlpineArt.beam(musher, Vector3(side * 0.4, 1.75, 1.1), Vector3(side * 0.6, 1.6, 0.8), 0.22, coral)
	AlpineArt.box(musher, Vector3(0, 1.96, 1.05), Vector3(0.67, 0.15, 0.68), AlpineArt.material(Color("#efc66c")))
	for item in musher.get_children():
		if item is MeshInstance3D:
			item.layers = musher_layer
	spray = CPUParticles3D.new()
	add_child(spray)
	spray.position = Vector3(0, 0.25, 1.5)
	spray.amount = 50
	spray.lifetime = 0.65
	spray.emitting = false
	spray.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	spray.emission_box_extents = Vector3(0.8, 0.05, 0.3)
	spray.direction = Vector3(0, 0.7, 1)
	spray.spread = 40
	spray.gravity = Vector3(0, -5, 0)
	spray.initial_velocity_min = 2.0
	spray.initial_velocity_max = 5.0
	spray.scale_amount_min = 0.05
	spray.scale_amount_max = 0.13
	var flake := SphereMesh.new()
	flake.radius = 0.5
	flake.height = 1.0
	flake.radial_segments = 4
	flake.rings = 2
	flake.material = white
	spray.mesh = flake

func _make_dog(pos: Vector3, index: int) -> void:
	var dog := Node3D.new()
	add_child(dog)
	dog.position = pos
	dogs.append(dog)
	var anatomy := DogModels.build(dog, breed, index, coral)
	legs.append_array(anatomy.legs)
	tails.append(anatomy.tail)

func animate(delta: float, speed: float, steer: float, drifting: bool) -> void:
	var moving := clampf(speed / 4.0, 0.0, 1.0)
	phase += delta * (3.0 + speed * 0.8)
	for i in range(dogs.size()):
		dogs[i].position.y = absf(sin(phase + i * 0.8)) * 0.1 * moving
		dogs[i].rotation.z = -steer * 0.06 * moving
		tails[i].rotation.y = sin(phase * 0.6 + i) * 0.3
		for j in range(4):
			legs[i * 4 + j].rotation.x = sin(phase + i * 0.8 + (0 if j == 0 or j == 3 else PI)) * 0.65 * moving
	rotation.z = lerp_angle(rotation.z, -steer * (0.09 if drifting else 0.04) * moving, 0.1)
	spray.emitting = speed > 5.0
	spray.initial_velocity_max = 8.0 if drifting else 4.0

func musher_eye() -> Vector3:
	return Vector3(0, 2.27, -1.7 if sled_style == 3 else 0.8)
