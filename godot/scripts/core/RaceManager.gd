extends Node
## Manages race state, timer, and lap progress.
## Single source of truth for race timing/state.

signal race_started
signal race_finished(final_time: float)

enum RaceState { COUNTDOWN, RACING, FINISHED }

@export var max_laps: int = 3
@export var num_checkpoints: int = 8

var state: RaceState = RaceState.COUNTDOWN
var race_time: float = 0.0
var current_lap: int = 0

@onready var lap_tracker: Node = $LapTracker

func _ready() -> void:
	# Set up the LapTracker
	lap_tracker.setup(num_checkpoints)
	lap_tracker.lap_completed.connect(_on_lap_completed)
	# Start racing immediately (no countdown for now)
	_start_race()

func _process(delta: float) -> void:
	if state == RaceState.RACING:
		race_time += delta

func _start_race() -> void:
	state = RaceState.RACING
	race_time = 0.0
	current_lap = 0
	GameState.change_state(GameState.State.RACING)
	race_started.emit()
	print("[RaceManager] Race started!")

func _on_lap_completed(lap_number: int) -> void:
	current_lap = lap_number
	print("[RaceManager] Lap %d / %d" % [current_lap, max_laps])
	if current_lap >= max_laps:
		_finish_race()

func _finish_race() -> void:
	state = RaceState.FINISHED
	GameState.change_state(GameState.State.RESULTS)
	race_finished.emit(race_time)
	print("[RaceManager] Race finished! Time: %.2f seconds" % race_time)

## Called by Checkpoint.gd when player drives through a checkpoint
func checkpoint_hit(index: int) -> void:
	if state == RaceState.RACING:
		lap_tracker.checkpoint_hit(index)

func get_time_string() -> String:
	var minutes := int(race_time) / 60
	var seconds := int(race_time) % 60
	var millis := int((race_time - int(race_time)) * 100)
	return "%02d:%02d.%02d" % [minutes, seconds, millis]

func restart() -> void:
	get_tree().reload_current_scene()
