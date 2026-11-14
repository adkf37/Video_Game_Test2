extends "res://scripts/vehicle/SledController.gd"
## Controls only: the shared controller handles all movement and snow physics.
const LAP_TRACKER = preload("res://scripts/track/LapTracker.gd")
var racer_name := "Rival"
var team_color := Color.WHITE
var grid_index := 0
var lane := 0.0
var cruise_throttle := 0.88
var lap_tracker: Node
var finished := false
var boost_wait := 5.0
var boost_left := 0.0
var stuck_time := 0.0
var recovery_count := 0
var attack_wait := 3.0

func _ready() -> void:
	is_player = false
	super._ready()
	lap_tracker = Node.new()
	lap_tracker.set_script(LAP_TRACKER)
	add_child(lap_tracker)
	lap_tracker.reset(-0.018)
	lap_tracker.lap_completed.connect(_lap_completed)
	var label := Label3D.new()
	add_child(label)
	label.position = Vector3(0, 3.3, 0)
	label.text = racer_name
	label.font_size = 40
	label.pixel_size = 0.018
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = team_color.lightened(0.35)
	label.outline_size = 10

func reset_race() -> void:
	finished = false
	lap_tracker.reset(-0.018)
	boost_energy = 100.0
	boost_wait = 5.0 + grid_index * 1.5
	boost_left = 0.0
	stuck_time = 0.0
	recovery_count = 0
	attack_wait = 3.0 + grid_index
	var frame: Transform3D = get_parent().get_node("Track").frame_at(-0.018)
	frame.origin += frame.basis.x * lane
	reset_to(frame)

func can_drive() -> bool:
	return not finished and race_manager.state in [race_manager.RaceState.RACING, race_manager.RaceState.FINISHED]

func drive_controls(delta: float) -> Dictionary:
	var lookahead := 9.0 + maxf(0, current_speed - 20) * 0.25
	var goal_frame := track.frame_at(route_progress + lookahead / track.total_length)
	var target_lane := lane
	var blocked := false
	var best_cost := INF
	# Score possible passing lanes against nearby teams instead of swerving blindly.
	for candidate: float in [-track.half_width * 0.5, 0.0, track.half_width * 0.5]:
		var cost := absf(candidate - lane) * 0.25
		for other in get_tree().get_nodes_in_group("racers"):
			if other == self or not other.can_drive():
				continue
			var local_offset: Vector3 = global_basis.inverse() * (other.global_position - global_position)
			if local_offset.z < 3.0 and local_offset.z > -19.0:
				var their_lane: float = (other.global_position - track.frame_at(route_progress).origin).dot(goal_frame.basis.x)
				cost += maxf(0, 3.0 - absf(candidate - their_lane)) * 5.0
				if local_offset.z < 0 and local_offset.z > -7 and absf(local_offset.x) < 2.0:
					blocked = true
		if cost < best_cost:
			best_cost = cost
			target_lane = candidate
	var goal := goal_frame.origin + goal_frame.basis.x * target_lane
	var direction := goal - global_position
	direction.y = 0
	var forward := -global_basis.z
	forward.y = 0
	var angle := forward.signed_angle_to(direction.normalized(), Vector3.UP)
	var steer := clampf(-angle * 2.5, -1, 1)
	var upcoming := track.frame_at(route_progress + 24.0 / track.total_length)
	var bend := absf((-goal_frame.basis.z).signed_angle_to(-upcoming.basis.z, Vector3.UP))
	var throttle := cruise_throttle
	if bend > 0.35:
		throttle *= 0.88
	if absf(angle) > 0.4:
		throttle *= 0.8
	if blocked:
		throttle = minf(throttle, 0.6)
	boost_wait -= delta
	attack_wait -= delta
	boost_left = maxf(0.0, boost_left - delta)
	if boost_wait <= 0 and boost_energy > 60 and absf(angle) < 0.10 and bend < 0.15 and not offroad and not blocked and impact_velocity.length() < 2:
		boost_left = 0.6 + GameState.difficulty * 0.4
		boost_wait = 15.0 - GameState.difficulty * 3 + grid_index
	stuck_time = stuck_time + delta if current_speed < 1.0 or offroad else 0.0
	if stuck_time > 4.0:
		var frame := track.frame_at(route_progress)
		frame.origin += frame.basis.x * lane
		reset_to(frame)
		lap_tracker.rebase(route_progress)
		stuck_time = 0.0
		recovery_count += 1
	var attack := attack_wait <= 0 and whip_cooldown <= 0 and whip_target() != null
	if attack:
		attack_wait = RaceCatalog.NPC_ATTACK_INTERVAL[GameState.difficulty] + grid_index * 0.5
	return {"throttle": throttle, "steer": steer, "drift": false,
		"boost": boost_left > 0 and absf(angle) < 0.25 and not blocked,
		"whip": attack}

func _lap_completed(number: int) -> void:
	if number >= race_manager.max_laps:
		finished = true
		race_manager.register_finish(self)
