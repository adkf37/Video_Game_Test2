extends Node
signal race_finished(final_time: float)
signal announcement(text: String)
enum RaceState { MENU, COUNTDOWN, RACING, PAUSED, FINISHED }
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
const RIVAL_SCRIPT = preload("res://scripts/ai/RivalController.gd")
const SLED_SCENE = preload("res://scenes/vehicles/Sled.tscn")
var rivals: Array[CharacterBody3D] = []
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
	lap_tracker.reset(-0.04)
	lap_tracker.lap_completed.connect(_on_lap_completed)
	call_deferred("_setup_grid")

func _setup_grid() -> void:
	var names := ["Juniper", "Kodiak", "Mika"]
	var colors := [Color("#65bc87"), Color("#8f86d9"), Color("#e0b448")]
	for i in range(3):
		var rival: CharacterBody3D = SLED_SCENE.instantiate()
		rival.set_script(RIVAL_SCRIPT)
		rival.name = "Rival%d" % i
		rival.racer_name = names[i]
		rival.team_color = colors[i]
		rival.grid_index = i
		rival.lane = (i - 1) * track.half_width * 0.36
		rival.cruise_throttle = RaceCatalog.NPC_PACE[GameState.difficulty] + (i - 1) * 0.025
		rival.get_node("DogTeam").breed = (i + 1) % 4
		rival.get_node("DogTeam").sled_style = (i + 1) % 4
		rival.get_node("DogTeam").team_color = colors[i]
		get_parent().add_child(rival)
		rivals.append(rival)
	apply_customization()
	_place_at_start()

func apply_customization() -> void:
	sled.visual.breed = GameState.breed
	sled.visual.sled_style = GameState.sled_style
	sled.visual.rebuild()

func _place_at_start() -> void:
	sled.reset_to(track.frame_at(-0.04))
	lap_tracker.reset(-0.04)
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
	player_finish_place = 0
	lap_start = 0.0
	current_lap = 0
	lap_times.clear()
	lap_tracker.reset(-0.04)
	new_record = false
	recovery_cooldown = 0.0
	sled.boost_energy = 100.0
	_place_at_start()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		if state == RaceState.PAUSED:
			resume()
		elif state == RaceState.RACING or state == RaceState.COUNTDOWN:
			resume_state = state
			state = RaceState.PAUSED
			get_tree().paused = true
	if Input.is_action_just_pressed("mute"):
		GameState.muted = not GameState.muted
		GameState.save()
	if state == RaceState.COUNTDOWN:
		countdown -= delta
		var number := ceili(countdown)
		if number != countdown_number and number > 0:
			countdown_number = number
			get_parent().get_node("RaceAudio").cue(550.0, 0.12)
		if countdown <= 0.0:
			state = RaceState.RACING
			announcement.emit("MUSH!")
			get_parent().get_node("RaceAudio").cue(880.0, 0.3)
	elif state == RaceState.RACING:
		race_time += delta
		elapsed_time += delta
		recovery_cooldown = maxf(0.0, recovery_cooldown - delta)
		if (Input.is_action_just_pressed("recover") or sled.position.y < -8.0) and recovery_cooldown <= 0.0:
			recover()
	elif state == RaceState.FINISHED and finish_order.size() < rivals.size() + 1:
		# Rivals still on the course finish naturally while results are displayed.
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
		lap_tracker.sample(track.nearest(sled.global_position).progress)
	if state in [RaceState.RACING, RaceState.FINISHED]:
		for rival in rivals:
			if not rival.finished:
				rival.lap_tracker.sample(track.nearest(rival.global_position).progress)

func _on_lap_completed(number: int) -> void:
	lap_times.append(race_time - lap_start)
	lap_start = race_time
	current_lap = number
	get_parent().get_node("RaceAudio").cue(1100.0, 0.25)
	if current_lap >= max_laps:
		register_finish(sled)
		player_finish_place = finish_order.find(sled) + 1
		state = RaceState.FINISHED
		new_record = GameState.record_run(race_time, lap_times.min())
		race_finished.emit(race_time)
	else:
		announcement.emit("FINAL LAP" if current_lap == max_laps - 1 else "LAP %d  /  %s" % [current_lap, GameState.time_text(lap_times.back())])

func recover() -> void:
	if state != RaceState.RACING:
		return
	var progress: float = track.nearest(sled.global_position).progress
	sled.reset_to(track.frame_at(progress))
	lap_tracker.rebase(progress)
	race_time += SledTuning.RECOVERY_PENALTY
	recovery_cooldown = 2.0
	announcement.emit("BACK ON TRAIL   +3s")

func register_finish(racer: Node) -> void:
	if racer in finish_order or not (racer == sled or racer in rivals):
		return
	var tracker: Node = lap_tracker if racer == sled else racer.lap_tracker
	if tracker.current_lap < max_laps:
		return
	finish_order.append(racer)
	finish_times[racer] = elapsed_time

func race_progress(racer: Node) -> float:
	var tracker: Node = lap_tracker if racer == sled else racer.lap_tracker
	return tracker.race_progress()

func standings() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var racers: Array[Node] = [sled]
	racers.append_array(rivals)
	for racer in racers:
		var is_player := racer == sled
		rows.append({"racer": racer, "name": "You" if is_player else racer.racer_name,
			"color": Color("#ed8668") if is_player else racer.team_color,
			"player": is_player, "finished": racer in finish_order,
			"order": finish_order.find(racer), "time": finish_times.get(racer, 0.0),
			"progress": race_progress(racer), "grid": 3 if is_player else racer.grid_index})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.finished != b.finished:
			return a.finished
		if a.finished:
			return a.order < b.order
		if not is_equal_approx(a.progress, b.progress):
			return a.progress > b.progress
		return a.grid < b.grid)
	return rows

func player_position() -> int:
	var rows := standings()
	for i in range(rows.size()):
		if rows[i].player:
			return i + 1
	return 4

func restart() -> void:
	start()
