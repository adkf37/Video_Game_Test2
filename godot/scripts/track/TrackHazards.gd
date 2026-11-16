extends Node3D
## Telegraphs and swept contacts shared by humans and NPCs. No random instant hits.
const WARNING_SECONDS := 2.0
const COCONUT_WARNING := 0.65
const COCONUT_FLIGHT := 0.95
var manager: Node
var track: AlpineTrack
var hazards: Array[Dictionary] = []
var coconuts: Array[Dictionary] = []
var previous_positions: Dictionary = {}
var previous_generations: Dictionary = {}
var elapsed := 0.0
var amber := AlpineArt.material(Color("#ffb63d"))
var cream := AlpineArt.material(Color("#fff4d2"))
var brown := AlpineArt.material(Color("#795033"))

func setup(race: Node, course: AlpineTrack) -> void:
	manager = race
	track = course
	var life: Node3D = track.get_node("TrackLife")
	for i in range(3):
		var progress := 0.19 + i * 0.265
		var frame := track.frame_at(progress)
		var side := 1.0 if i % 2 == 0 else -1.0
		var actor := Node3D.new()
		add_child(actor)
		var kind: String = ["polar bear", "coconut", "lollipop", "bus"][track.theme]
		match track.theme:
			0: life._bear(actor, 20 + i)
			1: life._lemur(actor, 20 + i)
			2: life._sweet(actor, 20 + i)
			3: life._bus(actor, 20 + i)
		var home := frame.origin + frame.basis.x * side * (track.half_width + 2.5)
		home.y = track.ground_height(home)
		actor.position = home
		actor.rotation.y = frame.basis.get_euler().y + side * PI * 0.5
		var sign_node := _sign(frame, side, ["BEAR CROSSING", "COCONUT ZONE", "FALLING SWEETS", "BUS CROSSING"][track.theme])
		var hazard := {"kind": kind, "actor": actor, "frame": frame, "progress": progress,
			"side": side, "home": home, "sign": sign_node, "phase": i * 4.1,
			"active": false, "warning": false, "lane": side * (track.half_width + 5),
			"width": 1.5, "depth": 1.5, "wait": 3.0 + i * 2}
		if kind == "lollipop":
			# From the verge to the outer edge of the candy head: < half the road.
			actor.scale = Vector3.ONE * (track.half_width * 0.96 / 8.25)
			hazard.home = frame.origin + frame.basis.x * side * (track.half_width + 0.1)
			hazard.home.y = track.ground_height(hazard.home) + 0.15
		hazards.append(hazard)
	if track.theme == 0:
		for i in range(2):
			var progress := 0.32 + i * 0.40
			var frame := track.frame_at(progress)
			var actor := Node3D.new()
			add_child(actor)
			AlpineArt.ellipsoid(actor, Vector3.ZERO, Vector3.ONE * 2.4, cream)
			for j in range(5):
				AlpineArt.ellipsoid(actor, Vector3(sin(j * 2) * 0.8, cos(j * 2) * 0.8, -0.7), Vector3.ONE * 0.6, cream)
			hazards.append({"kind": "snowball", "actor": actor, "frame": frame, "progress": progress,
				"side": -1.0, "home": frame.origin, "sign": _sign(frame, -1, "ROLLING SNOW"),
				"phase": i * 5.0 + 3, "active": false, "warning": false,
				"lane": 0.0, "width": 1.2, "depth": 1.2, "wait": 0.0})
	reset()

func _sign(frame: Transform3D, side: float, title: String) -> Node3D:
	var sign_node := Node3D.new()
	add_child(sign_node)
	sign_node.position = frame.origin + frame.basis.x * side * (track.half_width + 2) + frame.basis.z * 12
	sign_node.position.y = track.ground_height(sign_node.position)
	AlpineArt.cone(sign_node, Vector3(0, 1.2, 0), 0.10, 2.4, cream, 0.10)
	var label := Label3D.new()
	sign_node.add_child(label)
	label.position.y = 3
	label.text = "!  " + title
	label.font_size = 36
	label.pixel_size = 0.010
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("#ffca70")
	label.outline_size = 10
	return sign_node

func reset() -> void:
	elapsed = 0
	previous_positions.clear()
	previous_generations.clear()
	for coconut in coconuts:
		coconut.node.queue_free()
		coconut.marker.queue_free()
	coconuts.clear()
	for hazard in hazards:
		hazard["contacts"] = {}
		hazard.wait = 3.0 + hazard.phase
		_update_hazard(hazard, false)

func _physics_process(delta: float) -> void:
	if not manager or manager.state != manager.RaceState.RACING:
		return
	elapsed += delta
	for hazard in hazards:
		_update_hazard(hazard, true)
		if hazard.kind == "coconut":
			hazard.wait = maxf(0, hazard.wait - delta)
			if hazard.wait <= 0:
				_try_coconut(hazard)
		elif hazard.active:
			for racer in get_tree().get_nodes_in_group("racers"):
				if racer.can_drive():
					_contact(hazard, racer)
	_update_coconuts(delta)
	for racer in get_tree().get_nodes_in_group("racers"):
		previous_positions[racer] = racer.global_position
		previous_generations[racer] = racer.item_generation

func _update_hazard(hazard: Dictionary, running: bool) -> void:
	var frame: Transform3D = hazard.frame
	var actor: Node3D = hazard.actor
	var period := 17.0 - GameState.difficulty * 1.5
	var age: float = elapsed + hazard.phase
	var cycle := fposmod(age, period) if running else period - 1
	hazard.warning = running and cycle < WARNING_SECONDS
	hazard.active = false
	if hazard.kind == "coconut":
		actor.position = hazard.home
		actor.rotation.z = sin(elapsed * 2 + hazard.phase) * 0.08
		return
	if hazard.kind == "lollipop":
		var fall := 0.0
		if cycle >= 2 and cycle < 3:
			fall = smoothstep(2, 3, cycle)
		elif cycle >= 3 and cycle < 7:
			fall = 1
		elif cycle >= 7 and cycle < 8:
			fall = 1 - smoothstep(7, 8, cycle)
		actor.position = hazard.home
		actor.rotation = Vector3(fall * PI / 2, frame.basis.get_euler().y - hazard.side * PI / 2, 0)
		if hazard.warning:
			actor.rotation.z = sin(elapsed * 18) * 0.04
		hazard.width = track.half_width * 0.48
		hazard.depth = 2.25 * actor.scale.x + 0.15
		hazard.lane = hazard.side * (track.half_width + 0.1 - hazard.width)
		hazard.active = running and fall > 0.82
	else:
		var direction: float = hazard.side * (1 if int(floor(age / period)) % 2 == 0 else -1)
		var travel := clampf((cycle - WARNING_SECONDS) / 6.0, 0, 1)
		var extent := track.half_width + 6.0
		hazard.lane = lerpf(direction * extent, -direction * extent, travel)
		actor.position = frame.origin + frame.basis.x * hazard.lane
		actor.position.y = track.ground_height(actor.position)
		actor.rotation.y = frame.basis.get_euler().y + direction * PI / 2
		if hazard.kind == "polar bear":
			actor.position.y += sin(elapsed * 7) * 0.10
			hazard.width = 2.2
			hazard.depth = 1.1
		elif hazard.kind == "bus":
			hazard.width = 3.55
			hazard.depth = 1.45
		else:
			actor.position.y += 1.2
			actor.rotation.z = elapsed * 2
		hazard.active = running and cycle >= WARNING_SECONDS and cycle < 8
	if not hazard.active:
		hazard["contacts"] = {}
	hazard.sign.get_child(1).modulate = Color("#ff6947") if (hazard.warning or hazard.active) and sin(elapsed * 8) > 0 else Color("#ffca70")

func _contact(hazard: Dictionary, racer: CharacterBody3D) -> bool:
	var frame: Transform3D = hazard.frame
	var local := frame.affine_inverse() * racer.global_position
	var previous: Vector3 = previous_positions.get(racer, racer.global_position)
	if previous_generations.get(racer, racer.item_generation) != racer.item_generation or previous.distance_to(racer.global_position) > 12:
		previous = racer.global_position
	var from := frame.affine_inverse() * previous
	var center := Vector2(hazard.lane, 0)
	var extent := Vector2(hazard.width + 0.8, hazard.depth + 1.1)
	# Swept rectangle contact catches high-speed crossings without physics tunneling.
	var hit := false
	for step in range(7):
		var point := from.lerp(local, float(step) / 6)
		if absf(point.y) < 4 and absf(point.x - center.x) < extent.x and absf(point.z) < extent.y:
			hit = true
			break
	# One contact per crossing. Never move the sled back out of the obstacle:
	# after the brief delay it can drive through, even if the actor stays put.
	var contacts: Dictionary = hazard.get("contacts", {})
	hazard["contacts"] = contacts
	var id := racer.get_instance_id()
	if not hit:
		contacts.erase(id)
		return false
	if contacts.get(id, -1) == racer.item_generation:
		return false
	contacts[id] = racer.item_generation
	return racer.hit_hazard(hazard.kind)

func _try_coconut(hazard: Dictionary) -> void:
	var target: CharacterBody3D
	var nearest := 50.0
	for racer in get_tree().get_nodes_in_group("racers"):
		if not racer.can_drive() or racer.hazard_immunity > 0:
			continue
		var gap: float = fposmod(hazard.progress - racer.route_progress, 1.0) * track.total_length
		if gap > 12 and gap < nearest:
			nearest = gap
			target = racer
	if not target:
		return
	hazard.wait = 9.0 - GameState.difficulty
	var future: float = target.route_progress + maxf(target.current_speed, 8) * (COCONUT_WARNING + COCONUT_FLIGHT) / track.total_length
	var frame := track.frame_at(future)
	var target_lane: float = (target.global_position - track.frame_at(target.route_progress).origin).dot(frame.basis.x)
	var landing := frame.origin + frame.basis.x * clampf(target_lane, -track.half_width + 2, track.half_width - 2)
	landing.y = track.ground_height(landing) + 0.15
	var node := Node3D.new()
	add_child(node)
	AlpineArt.ellipsoid(node, Vector3.ZERO, Vector3.ONE * 0.7, brown)
	for x: float in [-0.12, 0.12]:
		AlpineArt.ellipsoid(node, Vector3(x, 0.08, -0.31), Vector3.ONE * 0.1, cream)
	var marker := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 1.65
	ring.outer_radius = 1.9
	ring.rings = 24
	ring.ring_segments = 8
	marker.mesh = ring
	marker.material_override = amber
	add_child(marker)
	marker.position = landing
	var start: Vector3 = hazard.actor.global_position + Vector3.UP * 2.8
	node.position = start
	coconuts.append({"node": node, "marker": marker, "start": start, "end": landing, "age": 0.0})
	for player in manager.players:
		if player.global_position.distance_to(landing) < 45:
			manager.get_parent().get_node("RaceAudio").event("warning", player.player_index)
			break

func _update_coconuts(delta: float) -> void:
	for i in range(coconuts.size() - 1, -1, -1):
		var coconut := coconuts[i]
		coconut.age += delta
		var t := clampf((coconut.age - COCONUT_WARNING) / COCONUT_FLIGHT, 0, 1)
		coconut.node.position = coconut.start.lerp(coconut.end, t) + Vector3.UP * sin(t * PI) * 6
		coconut.node.rotation += Vector3(3, 2, 1) * delta
		coconut.marker.scale = Vector3.ONE * (1 + sin(coconut.age * 16) * 0.07)
		if t >= 1:
			for racer in get_tree().get_nodes_in_group("racers"):
				var offset: Vector3 = racer.global_position - coconut.end
				if Vector2(offset.x, offset.z).length() < 2.0 and absf(offset.y) < 2.5:
					racer.hit_hazard("coconut")
			coconut.node.queue_free()
			coconut.marker.queue_free()
			coconuts.remove_at(i)

func lane_cost(progress: float, lane: float) -> float:
	var cost := 0.0
	for hazard in hazards:
		if not hazard.active and not hazard.warning:
			continue
		var ahead: float = fposmod(hazard.progress - progress, 1.0) * track.total_length
		if ahead < 35:
			cost += maxf(0, hazard.width + 2.3 - absf(lane - hazard.lane)) * 12
	for coconut in coconuts:
		var near := track.nearest(coconut.end)
		if fposmod(near.progress - progress, 1.0) * track.total_length < 35:
			var frame := track.frame_at(near.progress)
			var target_lane: float = (coconut.end - frame.origin).dot(frame.basis.x)
			cost += maxf(0, 3.0 - absf(lane - target_lane)) * 12
	return cost
