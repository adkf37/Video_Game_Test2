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
var race_manager: Node
var track: AlpineTrack
@onready var visual: Node3D = $DogTeam

func _ready() -> void:
	add_to_group("racers")
	if is_player:
		add_to_group("player")
	collision_layer = 2
	collision_mask = 1
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
	current_speed = 0.0
	steering = 0.0
	boosting = false
	drifting = false
	boost_latched = false
	var camera := get_parent().get_node_or_null("ChaseCamera")
	if camera and is_player:
		camera.snap()

func _physics_process(delta: float) -> void:
	if not track or not race_manager:
		return
	var nearest := track.nearest(global_position)
	route_progress = nearest.progress
	route_distance = nearest.distance
	offroad = route_distance > AlpineTrack.HALF_WIDTH
	var active := can_drive()
	var controls := drive_controls(delta) if active else {"throttle": 0.0, "steer": 0.0, "drift": false, "boost": false}
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
		limit = SledTuning.OFFROAD_SPEED
	var acceleration := SledTuning.BOOST_ACCEL if boosting else SledTuning.ACCELERATION
	if throttle > 0:
		current_speed = move_toward(current_speed, limit * throttle, acceleration * delta)
	elif throttle < 0:
		current_speed = move_toward(current_speed, SledTuning.REVERSE_SPEED * throttle, SledTuning.BRAKE_FORCE * delta)
	else:
		current_speed = move_toward(current_speed, 0, (SledTuning.DRAG if active else SledTuning.BRAKE_FORCE) * delta)
	if absf(current_speed) > 0.5:
		var response := clampf(absf(current_speed) / 8.0, 0.0, 1.0)
		rotate_y(-steering * SledTuning.TURN_RATE * response * signf(current_speed) * (SledTuning.DRIFT_TURN if drifting else 1.0) * delta)
	var forward := -global_basis.z
	var target_velocity := forward * current_speed
	var grip := SledTuning.DRIFT_GRIP if drifting else SledTuning.GRIP
	var blend := 1.0 - exp(-grip * delta)
	velocity.x = lerpf(velocity.x, target_velocity.x, blend)
	velocity.z = lerpf(velocity.z, target_velocity.z, blend)
	velocity.y -= SledTuning.GRAVITY * delta
	move_and_slide()
	for i in range(get_slide_collision_count()):
		var normal := get_slide_collision(i).get_normal()
		if absf(normal.y) < 0.4:
			current_speed *= 0.8
	var actual_speed := Vector2(get_real_velocity().x, get_real_velocity().z).length()
	visual.animate(delta, actual_speed, steering, drifting)
	# Keep dogs and runners aligned with gentle hills.
	if is_on_floor():
		var slope := asin(clampf(forward.dot(get_floor_normal()), -0.35, 0.35))
		visual.rotation.x = lerp_angle(visual.rotation.x, -slope, delta * 6.0)

func get_speed_kph() -> float:
	return Vector2(get_real_velocity().x, get_real_velocity().z).length() * 3.6

## NPCs provide controls through the same movement model as the player.
func can_drive() -> bool:
	return race_manager.state == race_manager.RaceState.RACING

func drive_controls(_delta: float) -> Dictionary:
	return {"throttle": Input.get_axis("move_back", "move_forward"),
		"steer": Input.get_axis("turn_left", "turn_right"),
		"drift": Input.is_action_pressed("drift"), "boost": Input.is_action_pressed("boost")}
