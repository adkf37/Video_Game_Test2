extends CharacterBody3D
var is_player := true
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
var whip_cooldown := 0.0
var hit_immunity := 0.0
var bump_count := 0
var whip_hits := 0
var race_manager: Node
var track: AlpineTrack
@onready var visual: Node3D = $DogTeam

func _ready() -> void:
	add_to_group("racers")
	if is_player:
		add_to_group("player")
	collision_layer = 2
	collision_mask = 3
	floor_snap_length = 1.2
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
	whip_cooldown = 0.0
	hit_immunity = 0.0
	bump_cooldowns.clear()
	visual.clear_attack()
	var camera := get_parent().get_node_or_null("ChaseCamera")
	if camera and is_player:
		camera.snap()

func _physics_process(delta: float) -> void:
	if not track or not race_manager:
		return
	var nearest := track.nearest(global_position)
	route_progress = nearest.progress
	route_distance = nearest.distance
	offroad = route_distance > track.half_width
	var active := can_drive()
	collision_layer = 2 if active else 0
	whip_cooldown = maxf(0, whip_cooldown - delta)
	hit_immunity = maxf(0, hit_immunity - delta)
	for id in bump_cooldowns.keys():
		bump_cooldowns[id] -= delta
		if bump_cooldowns[id] <= 0:
			bump_cooldowns.erase(id)
	impact_velocity = impact_velocity.move_toward(Vector3.ZERO, SledTuning.IMPACT_DECAY * delta)
	var controls := drive_controls(delta) if active else {"throttle": 0.0, "steer": 0.0, "drift": false, "boost": false, "whip": false}
	var throttle := float(controls.throttle)
	var target_steer := float(controls.steer)
	steering = move_toward(steering, target_steer, SledTuning.STEER_RESPONSE * delta)
	drifting = active and controls.drift and absf(current_speed) > 7.0
	if not controls.boost:
		boost_latched = false
	boosting = active and controls.boost and not boost_latched and boost_energy > 0 and throttle > 0 and not offroad
	if boosting:
		boost_energy = maxf(0, boost_energy - SledTuning.BOOST_DRAIN * delta)
		if boost_energy <= 0:
			boost_latched = true
	elif active:
		boost_energy = minf(100, boost_energy + SledTuning.BOOST_RECHARGE * delta)
	var limit := SledTuning.BOOST_SPEED if boosting else SledTuning.MAX_SPEED
	if offroad:
		limit = RaceCatalog.OFFROAD_CAPS[GameState.difficulty]
		current_speed = move_toward(current_speed, clampf(current_speed, -limit, limit), SledTuning.OFFROAD_BRAKE * delta)
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
	move_and_slide()
	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		var other := collision.get_collider()
		if other is CharacterBody3D and other.is_in_group("racers"):
			_resolve_bump(other, collision.get_normal())
		elif absf(collision.get_normal().y) < 0.4:
			current_speed *= 0.8
	if active and controls.get("whip", false):
		try_whip()
	var actual_speed := Vector2(get_real_velocity().x, get_real_velocity().z).length()
	visual.animate(delta, actual_speed, steering, drifting)
	if is_on_floor():
		var slope := asin(clampf(forward.dot(get_floor_normal()), -0.35, 0.35))
		visual.rotation.x = lerp_angle(visual.rotation.x, -slope, delta * 6.0)

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
	if is_player or other.is_player:
		race_manager.get_parent().get_node("RaceAudio").cue(150, 0.1)

func receive_impact(impulse: Vector3) -> void:
	impulse.y = 0
	impact_velocity = (impact_velocity + impulse).limit_length(SledTuning.MAX_IMPACT_SPEED)
	contact_velocity += impulse
	velocity.x = contact_velocity.x
	velocity.z = contact_velocity.z
	current_speed *= 0.9
	boosting = false

func whip_target() -> CharacterBody3D:
	var chosen: CharacterBody3D
	var closest := SledTuning.WHIP_RANGE
	for other in get_tree().get_nodes_in_group("racers"):
		if other == self or not other.can_drive() or other.hit_immunity > 0:
			continue
		var offset: Vector3 = other.global_position - global_position
		if absf(offset.y) > 2.0:
			continue
		offset.y = 0
		var distance := offset.length()
		if distance < 0.1 or distance >= closest:
			continue
		# Sweep beside the sled, rather than through the dog team in front.
		if absf(offset.normalized().dot(-global_basis.z)) > 0.8:
			continue
		chosen = other
		closest = distance
	return chosen

func try_whip() -> bool:
	if not can_drive() or whip_cooldown > 0:
		return false
	whip_cooldown = SledTuning.WHIP_COOLDOWN
	var target := whip_target()
	var side := 1.0
	if target:
		side = signf((target.global_position - global_position).dot(global_basis.x))
		var direction := (target.global_position - global_position).normalized()
		direction.y = 0
		target.receive_impact(direction.normalized() * SledTuning.WHIP_KNOCKBACK)
		target.hit_immunity = SledTuning.HIT_IMMUNITY
		whip_hits += 1
		if target.is_player:
			race_manager.announcement.emit("WHIPPED!  HOLD YOUR LINE")
		elif is_player:
			race_manager.announcement.emit("HIT  " + target.racer_name.to_upper())
	visual.show_whip(side)
	if is_player or (target and target.is_player):
		race_manager.get_parent().get_node("RaceAudio").cue(240, 0.12)
	return true

func get_speed_kph() -> float:
	return Vector2(get_real_velocity().x, get_real_velocity().z).length() * 3.6

func can_drive() -> bool:
	return race_manager.state == race_manager.RaceState.RACING

func drive_controls(_delta: float) -> Dictionary:
	return {"throttle": Input.get_axis("move_back", "move_forward"), "steer": Input.get_axis("turn_left", "turn_right"),
		"drift": Input.is_action_pressed("drift"), "boost": Input.is_action_pressed("boost"),
		"whip": Input.is_action_just_pressed("whip")}
