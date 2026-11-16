extends CharacterBody3D
var is_player := true
var player_index := 0
var offroad_cut := 0
var current_speed := 0.0
var steering := 0.0
var boost_energy := 100.0
var boosting := false
var drifting := false
var offroad := false
var route_progress := 0.0
var route_distance := 0.0
var boost_latched := false
var drive_velocity := Vector3.ZERO
var impact_velocity := Vector3.ZERO
var contact_velocity := Vector3.ZERO
var bump_cooldowns: Dictionary = {}
var has_bone := false
var bone_pending := false
var bone_immunity := 0.0
var distraction_time := 0.0
var distraction_goal := Vector3.ZERO
var item_generation := 0
var bump_count := 0
var bones_thrown := 0
const HAZARD_DELAY := 1.0
var hazard_kind := ""
var hazard_time := 0.0
var hazard_immunity := 0.0
var hazard_hits := 0
var race_manager: Node
var track: AlpineTrack
@onready var visual: Node3D = $DogTeam

func _ready() -> void:
	add_to_group("racers")
	if is_player:
		add_to_group("player")
	collision_layer = 2
	collision_mask = 3
	floor_snap_length = 1.8
	floor_max_angle = deg_to_rad(55)
	call_deferred("_connect_world")

func _connect_world() -> void:
	race_manager = get_tree().get_first_node_in_group("race")
	track = get_parent().get_node("Track")

func reset_to(frame: Transform3D) -> void:
	global_position = frame.origin + Vector3.UP * 0.5
	rotation = Vector3(0, frame.basis.get_euler().y, 0)
	velocity = Vector3.ZERO
	drive_velocity = Vector3.ZERO
	impact_velocity = Vector3.ZERO
	contact_velocity = Vector3.ZERO
	current_speed = 0.0
	steering = 0.0
	boosting = false
	drifting = false
	boost_latched = false
	clear_items()
	bump_cooldowns.clear()
	for camera in get_tree().get_nodes_in_group("race_cameras"):
		if camera.target == self:
			camera.snap()

func _physics_process(delta: float) -> void:
	if not track or not race_manager:
		return
	var nearest := track.nearest(global_position)
	route_progress = nearest.progress
	route_distance = nearest.distance
	offroad = route_distance > track.half_width
	offroad_cut = 0 if not offroad else (1 if route_distance <= track.half_width + RaceCatalog.FIRST_CUT_WIDTH else 2)
	var active := can_drive()
	collision_layer = 2 if active else 0
	if active:
		bone_immunity = maxf(0, bone_immunity - delta)
		hazard_immunity = maxf(0, hazard_immunity - delta)
	for id in bump_cooldowns.keys():
		bump_cooldowns[id] -= delta
		if bump_cooldowns[id] <= 0:
			bump_cooldowns.erase(id)
	impact_velocity = impact_velocity.move_toward(Vector3.ZERO, SledTuning.IMPACT_DECAY * delta)
	var chasing := active and distraction_time > 0
	var stunned := active and hazard_time > 0
	# A lure owns steering temporarily; do not run NPC stuck-recovery underneath it.
	var controls := drive_controls(delta) if active and not chasing and not stunned else {"throttle": 0.0, "steer": 0.0, "drift": false, "boost": false, "throw_item": false}
	if chasing:
		var direction := distraction_goal - global_position
		direction.y = 0
		var forward := -global_basis.z
		forward.y = 0
		controls = {"throttle": 0.5 if direction.length() > 1.4 else 0.0,
			"steer": clampf(-forward.signed_angle_to(direction.normalized(), Vector3.UP) * 3, -1, 1),
			"drift": false, "boost": false, "throw_item": false}
		distraction_time = maxf(0, distraction_time - delta)
	if stunned:
		hazard_time = maxf(0, hazard_time - delta)
		controls = {"throttle": 0.0, "steer": 0.0, "drift": false, "boost": false, "throw_item": false}
		current_speed = 0
		drive_velocity = Vector3.ZERO
		impact_velocity = Vector3.ZERO
	var throttle := float(controls.throttle)
	var target_steer := float(controls.steer)
	steering = move_toward(steering, target_steer, SledTuning.STEER_RESPONSE * delta)
	drifting = active and controls.drift and absf(current_speed) > 7.0
	if not controls.boost:
		boost_latched = false
	var was_boosting := boosting
	boosting = active and controls.boost and not boost_latched and boost_energy > 0 and throttle > 0 and not offroad
	if boosting and not was_boosting and is_player:
		race_manager.get_parent().get_node("RaceAudio").event("boost", player_index)
	if boosting:
		boost_energy = maxf(0, boost_energy - SledTuning.BOOST_DRAIN * delta)
		if boost_energy <= 0:
			boost_latched = true
	elif active:
		boost_energy = minf(100, boost_energy + SledTuning.BOOST_RECHARGE * delta)
	var limit := SledTuning.BOOST_SPEED if boosting else SledTuning.MAX_SPEED
	if offroad:
		limit = RaceCatalog.offroad_limit(route_distance, track.half_width, GameState.difficulty)
		current_speed = move_toward(current_speed, clampf(current_speed, -limit, limit), (8.0 if offroad_cut == 1 else SledTuning.OFFROAD_BRAKE) * delta)
	if chasing:
		limit = minf(limit, 12.0)
	var acceleration := SledTuning.BOOST_ACCEL if boosting else SledTuning.ACCELERATION
	if throttle > 0:
		current_speed = move_toward(current_speed, limit * throttle, acceleration * delta)
	elif throttle < 0:
		current_speed = move_toward(current_speed, -minf(SledTuning.REVERSE_SPEED, limit) * absf(throttle), SledTuning.BRAKE_FORCE * delta)
	else:
		current_speed = move_toward(current_speed, 0, (SledTuning.DRAG if active else SledTuning.BRAKE_FORCE) * delta)
	if absf(current_speed) > 0.5:
		var response := clampf(absf(current_speed) / 8.0, 0, 1)
		rotate_y(-steering * SledTuning.TURN_RATE * response * signf(current_speed) * (SledTuning.DRIFT_TURN if drifting else 1.0) * delta)
	var forward := -global_basis.z
	var grip := SledTuning.DRIFT_GRIP if drifting else SledTuning.GRIP
	drive_velocity = drive_velocity.lerp(forward * current_speed, 1.0 - exp(-grip * delta))
	velocity.x = drive_velocity.x + impact_velocity.x
	velocity.z = drive_velocity.z + impact_velocity.z
	velocity.y -= SledTuning.GRAVITY * delta
	contact_velocity = Vector3(velocity.x, 0, velocity.z)
	var intended_position := global_position + Vector3(velocity.x, 0, velocity.z) * delta
	move_and_slide()
	var ground_seam := false
	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		var other := collision.get_collider()
		if other is CharacterBody3D and other.is_in_group("racers"):
			_resolve_bump(other, collision.get_normal())
		elif other.is_in_group("driveable_ground") and absf(collision.get_normal().y) < 0.4:
			ground_seam = true
	if ground_seam:
		_cross_ground_seam(intended_position)
	if active and controls.get("throw_item", false):
		try_throw()
	var actual_speed := Vector2(get_real_velocity().x, get_real_velocity().z).length()
	visual.animate(delta, actual_speed, steering, drifting)
	if is_on_floor():
		var slope := asin(clampf(forward.dot(get_floor_normal()), -0.35, 0.35))
		visual.rotation.x = lerp_angle(visual.rotation.x, -slope, delta * 6.0)

func _cross_ground_seam(intended_position: Vector3) -> void:
	# Folded ribbon triangles can expose an internal edge as a horizontal wall.
	# Finish only this frame's horizontal move, still colliding with other sleds.
	var remaining := intended_position - global_position
	remaining.y = 0
	var mask := collision_mask
	collision_mask = 2
	var contact := move_and_collide(remaining)
	collision_mask = mask
	global_position.y = maxf(global_position.y, track.ground_height(global_position) + 0.05)
	if contact and contact.get_collider() is CharacterBody3D and contact.get_collider().is_in_group("racers"):
		_resolve_bump(contact.get_collider(), contact.get_normal())

func _resolve_bump(other: CharacterBody3D, normal: Vector3) -> void:
	if not can_drive() or not other.can_drive() or bump_cooldowns.has(other.get_instance_id()):
		return
	normal.y = 0
	if normal.length_squared() < 0.1:
		return
	normal = normal.normalized()
	var closing: float = -(contact_velocity - other.contact_velocity).dot(normal)
	if closing < 0.5:
		return
	var impulse := normal * minf((1.0 + SledTuning.BOUNCE_RESTITUTION) * closing * 0.5, SledTuning.MAX_BUMP_IMPULSE)
	bump_cooldowns[other.get_instance_id()] = SledTuning.BUMP_COOLDOWN
	other.bump_cooldowns[get_instance_id()] = SledTuning.BUMP_COOLDOWN
	receive_impact(impulse)
	other.receive_impact(-impulse)
	bump_count += 1
	other.bump_count += 1
	var audio := race_manager.get_parent().get_node("RaceAudio")
	if is_player or other.is_player:
		audio.event("crash", player_index if is_player else other.player_index)
	else:
		audio.event_at("crash", (global_position + other.global_position) * 0.5)

func receive_impact(impulse: Vector3) -> void:
	impulse.y = 0
	impact_velocity = (impact_velocity + impulse).limit_length(SledTuning.MAX_IMPACT_SPEED)
	contact_velocity += impulse
	velocity.x = contact_velocity.x
	velocity.z = contact_velocity.z
	current_speed *= 0.9
	boosting = false

func clear_items() -> void:
	has_bone = false
	bone_pending = false
	bone_immunity = 0.0
	distraction_time = 0.0
	hazard_time = 0.0
	hazard_immunity = 0.0
	item_generation += 1

func distract(point: Vector3) -> void:
	if not can_drive() or bone_immunity > 0 or distraction_time > 0:
		return
	distraction_goal = point
	distraction_time = race_manager.items.CHASE_SECONDS
	bone_immunity = distraction_time + race_manager.items.PROTECTION_SECONDS
	boosting = false
	current_speed = minf(current_speed, 12.0)
	if is_player:
		race_manager.announcement.emit("GOLDEN BONE! / DOGS DISTRACTED FOR 1s")

func try_throw() -> bool:
	return race_manager.items.throw_bone(self) if race_manager.items else false

func item_hint() -> String:
	if hazard_time > 0:
		return "%s / %.1fs" % [hazard_kind.to_upper(), hazard_time]
	if distraction_time > 0:
		return "CHASING BONE / %.1fs" % distraction_time
	if not has_bone:
		return "COLLECT A GOLDEN BONE"
	var key := "E" if player_index == 0 else "COMMA"
	var target: Node = race_manager.items.target_for(self) if race_manager.items else null
	if not target:
		return "GOLDEN BONE / GET CLOSER TO A RIVAL"
	var who: String = ("PLAYER %d" % (target.player_index + 1)) if target.is_player else target.racer_name.to_upper()
	return key + " / THROW GOLDEN BONE > " + who

func get_speed_kph() -> float:
	return Vector2(get_real_velocity().x, get_real_velocity().z).length() * 3.6

func hit_hazard(kind: String) -> bool:
	if not can_drive() or hazard_immunity > 0:
		return false
	hazard_hits += 1
	hazard_immunity = 3.0
	boosting = false
	hazard_kind = kind
	hazard_time = HAZARD_DELAY
	current_speed = 0
	drive_velocity = Vector3.ZERO
	impact_velocity = Vector3.ZERO
	contact_velocity = Vector3.ZERO
	velocity.x = 0
	velocity.z = 0
	var audio := race_manager.get_parent().get_node("RaceAudio")
	var sound := "coconut" if kind == "coconut" else "crash"
	if is_player:
		audio.event(sound, player_index)
		race_manager.announcement.emit(kind.to_upper() + " / 1s DELAY")
	else:
		audio.event_at(sound, global_position)
	return true

func can_drive() -> bool:
	return race_manager != null and race_manager.state == race_manager.RaceState.RACING and self not in race_manager.finish_order

func input_prefix() -> String:
	return ("p1_" if player_index == 0 else "p2_") if GameState.race_mode == 1 else ""

func drive_controls(_delta: float) -> Dictionary:
	if GameState.mobile_mode and GameState.mobile_input:
		return GameState.mobile_input.controls()
	var prefix := input_prefix()
	return {"throttle": Input.get_axis(prefix + "move_back", prefix + "move_forward"), "steer": Input.get_axis(prefix + "turn_left", prefix + "turn_right"),
		"drift": Input.is_action_pressed(prefix + "drift"), "boost": Input.is_action_pressed(prefix + "boost"),
		"throw_item": Input.is_action_just_pressed(prefix + "throw_item")}
