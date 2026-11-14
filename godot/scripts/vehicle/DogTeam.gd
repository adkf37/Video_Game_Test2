extends Node3D
## Four expressive geometric huskies, articulated legs, tow lines, sled and musher.
@export var team_color := Color("#e7684c")
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
	coral.albedo_color = team_color
	for row in range(2):
		for side: float in [-1.0, 1.0]:
			_make_dog(Vector3(side * 0.9, 0, -3.2 - row * 2.45), dogs.size())
	AlpineArt.beam(self, Vector3(0, 0.65, -0.8), Vector3(0, 0.7, -6.5), 0.045, rope)
	for z: float in [-3.0, -5.45]:
		for side: float in [-1.0, 1.0]:
			AlpineArt.beam(self, Vector3(0, 0.65, z + 0.65), Vector3(side * 0.9, 0.65, z), 0.035, rope)
	for side: float in [-1.0, 1.0]:
		AlpineArt.box(self, Vector3(side * 0.65, 0.15, 0), Vector3(0.12, 0.12, 3.6), steel)
		AlpineArt.beam(self, Vector3(side * 0.65, 0.15, -1.8), Vector3(side * 0.65, 0.6, -2.05), 0.13, steel)
		AlpineArt.box(self, Vector3(side * 0.65, 0.48, 0), Vector3(0.08, 0.6, 2.5), timber)
		AlpineArt.box(self, Vector3(side * 0.65, 0.85, 0), Vector3(0.12, 0.12, 2.7), timber)
		AlpineArt.beam(self, Vector3(side * 0.65, 0.6, 0.8), Vector3(side * 0.65, 1.65, 1.1), 0.1, timber)
	AlpineArt.box(self, Vector3(0, 0.4, -0.1), Vector3(1.25, 0.18, 2.5), timber)
	AlpineArt.ellipsoid(self, Vector3(0, 0.7, -0.45), Vector3(1.15, 0.65, 1.7), coral)
	AlpineArt.box(self, Vector3(0, 0.92, -0.45), Vector3(0.1, 0.03, 1.6), white)
	AlpineArt.beam(self, Vector3(-0.65, 1.65, 1.1), Vector3(0.65, 1.65, 1.1), 0.12, timber)
	# A bundled-up musher gives the dog team a clear sense of scale.
	for side: float in [-1.0, 1.0]:
		AlpineArt.box(self, Vector3(side * 0.24, 0.75, 1.15), Vector3(0.23, 0.85, 0.28), dark)
	AlpineArt.ellipsoid(self, Vector3(0, 1.5, 1.1), Vector3(0.95, 1.1, 0.65), coral)
	AlpineArt.ellipsoid(self, Vector3(0, 2.15, 1.0), Vector3(0.66, 0.66, 0.66), white)
	AlpineArt.ellipsoid(self, Vector3(0, 2.35, 1.06), Vector3(0.7, 0.45, 0.7), dark)
	AlpineArt.ellipsoid(self, Vector3(0, 2.62, 1.06), Vector3.ONE * 0.2, coral)
	for side: float in [-1.0, 1.0]:
		AlpineArt.beam(self, Vector3(side * 0.4, 1.75, 1.1), Vector3(side * 0.6, 1.6, 0.8), 0.22, coral)
	AlpineArt.box(self, Vector3(0, 1.96, 1.05), Vector3(0.67, 0.15, 0.68), AlpineArt.material(Color("#efc66c")))
	spray = CPUParticles3D.new()
	add_child(spray)
	spray.position = Vector3(0, 0.25, 1.5)
	spray.amount = 90
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
	var fur := dark if index != 1 else AlpineArt.material(Color("#a57753"))
	AlpineArt.ellipsoid(dog, Vector3(0, 0.87, 0), Vector3(0.68, 0.7, 1.3), white)
	AlpineArt.ellipsoid(dog, Vector3(0, 1.06, 0.12), Vector3(0.7, 0.45, 1.1), fur)
	AlpineArt.ellipsoid(dog, Vector3(0, 1.17, -0.63), Vector3(0.64, 0.65, 0.68), fur)
	AlpineArt.ellipsoid(dog, Vector3(0, 1.04, -0.87), Vector3(0.49, 0.36, 0.48), white)
	AlpineArt.ellipsoid(dog, Vector3(0, 1.08, -1.1), Vector3(0.22, 0.16, 0.15), nose)
	for side: float in [-1.0, 1.0]:
		AlpineArt.cone(dog, Vector3(side * 0.22, 1.55, -0.59), 0.17, 0.43, fur)
		AlpineArt.ellipsoid(dog, Vector3(side * 0.23, 1.25, -0.88), Vector3(0.11, 0.13, 0.07), nose)
		for z: float in [-0.42, 0.43]:
			var pivot := Node3D.new()
			dog.add_child(pivot)
			pivot.position = Vector3(side * 0.25, 0.72, z)
			AlpineArt.box(pivot, Vector3(0, -0.25, 0), Vector3(0.16, 0.52, 0.18), white)
			AlpineArt.ellipsoid(pivot, Vector3(0, -0.49, -0.06), Vector3(0.23, 0.17, 0.31), white)
			legs.append(pivot)
	AlpineArt.box(dog, Vector3(0, 1.18, -0.2), Vector3(0.72, 0.1, 0.17), coral)
	AlpineArt.box(dog, Vector3(0, 1.29, 0.07), Vector3(0.12, 0.07, 0.6), coral)
	var tail := Node3D.new()
	dog.add_child(tail)
	tail.position = Vector3(0, 1.0, 0.58)
	var fluff := AlpineArt.ellipsoid(tail, Vector3(0, 0.22, 0.23), Vector3(0.28, 0.32, 0.8), white)
	fluff.rotation.x = -0.55
	tails.append(tail)

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
