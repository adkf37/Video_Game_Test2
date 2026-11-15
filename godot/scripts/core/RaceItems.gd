extends Node3D
## Shared pickups and visible throws. One inventory slot per racer, no free attacks.
const RANGE := 26.0
const CHASE_SECONDS := 2.0
const PROTECTION_SECONDS := 4.0
const FLIGHT_SECONDS := 0.55
const RESPAWN_SECONDS := 10.0
var manager: Node
var track: AlpineTrack
var pickups: Array[Dictionary] = []
var flights: Array[Dictionary] = []
var elapsed := 0.0
var gold := AlpineArt.material(Color("#ffc94c"), 0.25)

func setup(race: Node, course: AlpineTrack) -> void:
	manager = race
	track = course
	gold.emission_enabled = true
	gold.emission = Color("#b97618")
	gold.emission_energy_multiplier = 0.45
	# Three single pickups replace 21: 14.3%, the nearest whole count to 15%.
	for station in range(3):
		var frame := track.frame_at(0.10 + station * 0.30)
		var point: Vector3 = frame.origin + frame.basis.x * track.half_width * [-0.55, 0.45, -0.25][station]
		point.y = track.ground_height(point) + 1.25
		var bone := make_bone()
		bone.position = point
		pickups.append({"node": bone, "home": point, "wait": 0.0})

func make_bone() -> Node3D:
	var bone := Node3D.new()
	add_child(bone)
	AlpineArt.beam(bone, Vector3(-0.5, 0, 0), Vector3(0.5, 0, 0), 0.26, gold)
	for side: float in [-1, 1]:
		for end: float in [-1, 1]:
			AlpineArt.ellipsoid(bone, Vector3(side * 0.55, end * 0.18, 0), Vector3.ONE * 0.43, gold)
	return bone

func reset() -> void:
	for flight in flights:
		if is_instance_valid(flight.target):
			flight.target.bone_pending = false
		flight.node.queue_free()
	flights.clear()
	for pickup in pickups:
		pickup.wait = 0.0
		pickup.node.visible = true
	elapsed = 0.0

func target_for(thrower: Node3D) -> CharacterBody3D:
	var chosen: CharacterBody3D
	var closest := RANGE
	for other in get_tree().get_nodes_in_group("racers"):
		if other == thrower or not other.can_drive() or other.bone_pending or other.distraction_time > 0 or other.bone_immunity > 0:
			continue
		var offset: Vector3 = other.global_position - thrower.global_position
		if absf(offset.y) > 4:
			continue
		offset.y = 0
		var distance := offset.length()
		# Do not target across a neighboring stretch of a hairpin.
		var route_gap: float = absf(other.route_progress - thrower.route_progress)
		if minf(route_gap, 1.0 - route_gap) * track.total_length > RANGE * 1.8:
			continue
		if distance < closest:
			chosen = other
			closest = distance
	return chosen

func throw_bone(thrower: Node3D) -> bool:
	if manager.state != manager.RaceState.RACING or not thrower.can_drive() or not thrower.has_bone or thrower.distraction_time > 0 or thrower.hazard_time > 0:
		return false
	var target := target_for(thrower)
	if not target:
		if thrower.is_player:
			manager.announcement.emit("KEEP YOUR BONE / GET CLOSER TO A RIVAL")
		return false
	var progress: float = track.nearest(target.global_position).progress
	var frame := track.frame_at(progress + (8.0 + maxf(target.current_speed, 0) * FLIGHT_SECONDS) / track.total_length)
	var lane: float = (target.global_position - track.frame_at(progress).origin).dot(frame.basis.x)
	var side := -1.0 if lane < 0 else 1.0
	var landing := frame.origin + frame.basis.x * side * (track.half_width + 3.0)
	landing.y = track.ground_height(landing) + 0.4
	var start := thrower.global_position + Vector3.UP * 2.0
	var bone := make_bone()
	bone.global_position = start
	thrower.has_bone = false
	thrower.bones_thrown += 1
	target.bone_pending = true
	flights.append({"node": bone, "start": start, "end": landing, "age": 0.0,
		"target": target, "generation": target.item_generation, "landed": false})
	if thrower.is_player:
		manager.get_parent().get_node("RaceAudio").event("throw", thrower.player_index)
	else:
		manager.get_parent().get_node("RaceAudio").event_at("throw", thrower.global_position)
	return true

func _physics_process(delta: float) -> void:
	if not manager or manager.state != manager.RaceState.RACING:
		return
	elapsed += delta
	for pickup in pickups:
		pickup.wait = maxf(0, pickup.wait - delta)
		pickup.node.visible = pickup.wait <= 0
		pickup.node.position.y = pickup.home.y + sin(elapsed * 2.5 + pickup.home.x) * 0.18
		pickup.node.rotation.y += delta * 1.1
		if pickup.wait > 0:
			continue
		for racer in get_tree().get_nodes_in_group("racers"):
			if not racer.can_drive() or racer.has_bone or racer.distraction_time > 0 or racer.hazard_time > 0:
				continue
			var offset: Vector3 = racer.global_position - pickup.home
			if absf(offset.y) > 2.5:
				continue
			offset.y = 0
			if offset.length() <= 1.55:
				racer.has_bone = true
				pickup.wait = RESPAWN_SECONDS
				pickup.node.visible = false
				if racer.is_player:
					manager.announcement.emit("GOLDEN BONE! / " + ("E" if racer.player_index == 0 else "COMMA") + " TO THROW")
					manager.get_parent().get_node("RaceAudio").event("pickup", racer.player_index)
				break
	for i in range(flights.size() - 1, -1, -1):
		var flight := flights[i]
		flight.age += delta
		var t := clampf(flight.age / FLIGHT_SECONDS, 0, 1)
		flight.node.global_position = flight.start.lerp(flight.end, t) + Vector3.UP * sin(t * PI) * 4.0
		flight.node.rotation.z = t * TAU * 2
		if not flight.landed and t >= 1:
			flight.landed = true
			var target: Node3D = flight.target
			if is_instance_valid(target) and target.item_generation == flight.generation:
				target.bone_pending = false
				if target.can_drive() and target.global_position.distance_to(flight.end) < 22:
					target.distract(flight.end)
		if flight.age >= FLIGHT_SECONDS + CHASE_SECONDS:
			flight.node.queue_free()
			flights.remove_at(i)
