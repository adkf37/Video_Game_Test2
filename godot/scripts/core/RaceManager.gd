extends Node
signal race_finished(final_time: float)
signal announcement(text: String)
enum RaceState { MENU, COUNTDOWN, RACING, PAUSED, FINISHED }
const RIVAL_SCRIPT = preload("res://scripts/ai/RivalController.gd")
const SLED_SCENE = preload("res://scenes/vehicles/Sled.tscn")
const LAP_SCRIPT = preload("res://scripts/track/LapTracker.gd")
var items: Node3D
var hazards: Node3D
var estimated_finishes: Dictionary = {}
var state := RaceState.MENU
var resume_state := RaceState.RACING
var max_laps := 3
var race_time := 0.0
var lap_start := 0.0
var lap_times: Array[float] = []
var current_lap := 0
var countdown := 3.5
var new_record := false
var recovery_cooldown := 0.0
var countdown_number := 4
var rivals: Array[CharacterBody3D] = []
var players: Array[CharacterBody3D] = []
var player_trackers: Array[Node] = []
var player_times := [0.0, 0.0]
var player_lap_starts := [0.0, 0.0]
var player_splits: Array = [[], []]
var recovery_wait := [0.0, 0.0]
var finish_order: Array[Node] = []
var finish_times: Dictionary = {}
var elapsed_time := 0.0
var player_finish_place := 0
@onready var lap_tracker: Node = $LapTracker
@onready var sled: CharacterBody3D = get_parent().get_node("PlayerSled")
@onready var track: Node3D = get_parent().get_node("Track")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("race")
	players.append(sled)
	player_trackers.append(lap_tracker)
	lap_tracker.reset(-0.04)
	lap_tracker.lap_completed.connect(_on_lap_completed)
	call_deferred("_setup_grid")

func _setup_grid() -> void:
	if GameState.race_mode == 1:
		var second: CharacterBody3D = SLED_SCENE.instantiate()
		second.name = "PlayerTwo"
		second.player_index = 1
		get_parent().add_child(second)
		players.append(second)
		var tracker := Node.new()
		tracker.set_script(LAP_SCRIPT)
		add_child(tracker)
		player_trackers.append(tracker)
		tracker.lap_completed.connect(func(number: int): _human_lap(1, number))
	var names := ["Juniper", "Kodiak", "Mika"]
	var colors := [Color("#65bc87"), Color("#8f86d9"), Color("#e0b448")]
	for i in range(4 - players.size()):
		var rival: CharacterBody3D = SLED_SCENE.instantiate()
		rival.set_script(RIVAL_SCRIPT)
		rival.name = "Rival%d" % i
		rival.racer_name = names[i]
		rival.team_color = colors[i]
		rival.grid_index = i
		rival.lane = (i - (3 - players.size()) * 0.5) * track.half_width * 0.5
		rival.cruise_throttle = (RaceCatalog.NPC_PACE[GameState.difficulty] + (i - 1) * 0.025) * RaceCatalog.CHALLENGE_MULTIPLIER
		rival.get_node("DogTeam").breed = (i + 1) % 4
		rival.get_node("DogTeam").sled_style = (i + 1) % 4
		rival.get_node("DogTeam").team_color = colors[i]
		get_parent().add_child(rival)
		rivals.append(rival)
	items = Node3D.new()
	items.name = "RaceItems"
	items.set_script(preload("res://scripts/core/RaceItems.gd"))
	get_parent().add_child(items)
	items.setup(self, track)
	hazards = Node3D.new()
	hazards.name = "TrackHazards"
	hazards.set_script(preload("res://scripts/track/TrackHazards.gd"))
	get_parent().add_child(hazards)
	hazards.setup(self, track)
	apply_customization()
	_place_at_start()

func apply_customization() -> void:
	for i in range(players.size()):
		var visual: Node3D = players[i].visual
		visual.breed = GameState.breed if i == 0 else GameState.breed2
		visual.sled_style = GameState.sled_style if i == 0 else GameState.sled_style2
		visual.team_color = Color("#ed8668") if i == 0 else Color("#5fcddd")
		visual.musher_layer = 2 if i == 0 else 4
		visual.rebuild()

func _place_at_start() -> void:
	if items:
		items.reset()
	if hazards:
		hazards.reset()
	for i in range(players.size()):
		var frame: Transform3D = track.frame_at(-0.04)
		if players.size() == 2:
			frame.origin += frame.basis.x * (-2.7 if i == 0 else 2.7)
		players[i].reset_to(frame)
		player_trackers[i].reset(-0.04)
	for rival in rivals:
		rival.reset_race()

func start() -> void:
	get_tree().paused = false
	state = RaceState.COUNTDOWN
	countdown = 3.5
	countdown_number = 4
	race_time = 0.0
	elapsed_time = 0.0
	finish_order.clear()
	finish_times.clear()
	estimated_finishes.clear()
	player_finish_place = 0
	lap_start = 0.0
	current_lap = 0
	lap_times.clear()
	player_times = [0.0, 0.0]
	player_lap_starts = [0.0, 0.0]
	player_splits = [[], []]
	recovery_wait = [0.0, 0.0]
	new_record = false
	recovery_cooldown = 0.0
	for player in players:
		player.boost_energy = 100.0
	_place_at_start()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		if state == RaceState.PAUSED:
			GameState.play_ui("close")
			resume()
		elif state in [RaceState.RACING, RaceState.COUNTDOWN]:
			GameState.play_ui("open")
			resume_state = state
			state = RaceState.PAUSED
			get_tree().paused = true
	if Input.is_action_just_pressed("mute"):
		GameState.muted = not GameState.muted
		GameState.play_ui("toggle")
		if not GameState.practice_run:
			GameState.save()
	if Input.is_action_just_pressed("volume_up"):
		GameState.change_volume(1)
	if Input.is_action_just_pressed("volume_down"):
		GameState.change_volume(-1)
	if state == RaceState.COUNTDOWN:
		countdown -= delta
		var number := ceili(countdown)
		if number != countdown_number and number > 0:
			countdown_number = number
			get_parent().get_node("RaceAudio").cue(550.0, 0.12)
		if countdown <= 0:
			state = RaceState.RACING
			announcement.emit("MUSH!")
			get_parent().get_node("RaceAudio").cue(880.0, 0.3)
	elif state == RaceState.RACING:
		elapsed_time += delta
		for i in range(players.size()):
			if players[i] in finish_order:
				continue
			player_times[i] += delta
			recovery_wait[i] = maxf(0, recovery_wait[i] - delta)
			if (Input.is_action_just_pressed(players[i].input_prefix() + "recover") or players[i].position.y < -8) and recovery_wait[i] <= 0:
				recover(i)
		race_time = player_times[0]
		recovery_cooldown = recovery_wait[0]
	elif state == RaceState.FINISHED and finish_order.size() < 4:
		elapsed_time += delta

func resume() -> void:
	state = resume_state
	get_tree().paused = false

func menu() -> void:
	get_tree().paused = false
	state = RaceState.MENU
	_place_at_start()

func _physics_process(_delta: float) -> void:
	if state == RaceState.RACING:
		for i in range(players.size()):
			if players[i] not in finish_order:
				player_trackers[i].sample(track.nearest(players[i].global_position).progress)
	if state in [RaceState.RACING, RaceState.FINISHED]:
		for rival in rivals:
			if not rival.finished:
				rival.lap_tracker.sample(track.nearest(rival.global_position).progress)

func _on_lap_completed(number: int) -> void:
	_human_lap(0, number)

func _human_lap(index: int, number: int) -> void:
	player_splits[index].append(player_times[index] - player_lap_starts[index])
	player_lap_starts[index] = player_times[index]
	if index == 0:
		current_lap = number
		lap_start = player_lap_starts[0]
		lap_times.assign(player_splits[0])
	get_parent().get_node("RaceAudio").cue(1100.0, 0.25)
	if number >= max_laps:
		register_finish(players[index])
		if index == 0:
			player_finish_place = finish_order.find(sled) + 1
		var all_done := true
		for player in players:
			if player not in finish_order:
				all_done = false
		if all_done:
			state = RaceState.FINISHED
			if players.size() == 1:
				_estimate_remaining_rivals()
			get_parent().get_node("RaceAudio").event("finish")
			new_record = GameState.record_run(player_times[0], lap_times.min()) if players.size() == 1 else false
			race_finished.emit(player_times[0])
		else:
			announcement.emit("PLAYER %d FINISHED!  OTHER PLAYER STILL RACING" % (index + 1))
	else:
		announcement.emit(("P%d  /  " % (index + 1) if players.size() == 2 else "") + ("FINAL LAP" if number == max_laps - 1 else "LAP %d COMPLETE" % number))

func recover(index: int = 0) -> void:
	if state != RaceState.RACING or players[index] in finish_order:
		return
	var player := players[index]
	var progress: float = track.nearest(player.global_position).progress
	var frame: Transform3D = track.frame_at(progress)
	# Offset a recovery if another active racer is occupying the center line.
	for other in get_tree().get_nodes_in_group("racers"):
		if other != player and other.can_drive() and other.global_position.distance_to(frame.origin) < 4:
			frame.origin += frame.basis.x * (3.0 if index == 0 else -3.0)
			break
	player.reset_to(frame)
	player_trackers[index].rebase(progress)
	player_times[index] += SledTuning.RECOVERY_PENALTY
	recovery_wait[index] = 2.0
	race_time = player_times[0]
	recovery_cooldown = recovery_wait[0]
	announcement.emit(("P%d  /  " % (index + 1) if players.size() == 2 else "") + "BACK ON TRAIL   +3s")

func tracker_for(racer: Node) -> Node:
	var index := players.find(racer)
	return player_trackers[index] if index >= 0 else racer.lap_tracker

func register_finish(racer: Node) -> void:
	if racer in finish_order or not (racer in players or racer in rivals):
		return
	if tracker_for(racer).current_lap < max_laps:
		return
	racer.clear_items()
	finish_order.append(racer)
	finish_times[racer] = elapsed_time

func race_progress(racer: Node) -> float:
	return tracker_for(racer).race_progress()

func _estimate_remaining_rivals() -> void:
	# Keep real finishes and the on-track order. Project remaining distance using
	# each rival's average pace so a temporary slowdown doesn't inflate its time.
	var previous_time := elapsed_time
	for row in standings():
		var rival: Node = row.racer
		if row.finished or row.player:
			continue
		var progress: float = clampf(row.progress, 0, max_laps)
		var average_speed: float = progress * track.total_length / maxf(elapsed_time, 1)
		if progress < 0.05:
			average_speed = SledTuning.MAX_SPEED * rival.cruise_throttle * 0.8
		var remaining: float = (max_laps - progress) * track.total_length
		var estimate: float = elapsed_time + remaining / maxf(average_speed, 3)
		estimate = maxf(estimate, previous_time + 0.01)
		previous_time = estimate
		rival.finished = true
		rival.clear_items()
		finish_order.append(rival)
		finish_times[rival] = estimate
		estimated_finishes[rival] = true

func standings() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var racers: Array[Node] = []
	racers.append_array(players)
	racers.append_array(rivals)
	for racer in racers:
		var index := players.find(racer)
		var human := index >= 0
		var label: String = ("You" if players.size() == 1 else "Player %d" % (index + 1)) if human else racer.racer_name
		rows.append({"racer": racer, "name": label,
			"color": (Color("#ed8668") if index == 0 else Color("#5fcddd")) if human else racer.team_color,
			"player": human, "player_index": index, "finished": racer in finish_order,
			"order": finish_order.find(racer), "time": finish_times.get(racer, 0.0),
			"estimated": estimated_finishes.has(racer),
			"progress": race_progress(racer), "grid": 2 + index if human else racer.grid_index})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.finished != b.finished:
			return a.finished
		if a.finished:
			return a.order < b.order
		if not is_equal_approx(a.progress, b.progress):
			return a.progress > b.progress
		return a.grid < b.grid)
	return rows

func player_position(index: int = 0) -> int:
	var rows := standings()
	for i in range(rows.size()):
		if rows[i].player_index == index:
			return i + 1
	return 4

func restart() -> void:
	start()
