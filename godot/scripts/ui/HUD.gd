extends CanvasLayer
## In-race HUD: timer, lap counter, speed, and finish panel.

@onready var timer_label: Label = $MarginContainer/VBoxContainer/TimerLabel
@onready var lap_label: Label = $MarginContainer/VBoxContainer/LapLabel
@onready var speed_label: Label = $MarginContainer/VBoxContainer/SpeedLabel
@onready var checkpoint_label: Label = $MarginContainer/VBoxContainer/CheckpointLabel
@onready var finish_panel: PanelContainer = $FinishPanel
@onready var finish_time_label: Label = $FinishPanel/VBoxContainer/FinishTimeLabel
@onready var restart_button: Button = $FinishPanel/VBoxContainer/RestartButton

var race_manager: Node = null
var player_sled: Node = null

func _ready() -> void:
	finish_panel.visible = false
	restart_button.pressed.connect(_on_restart_pressed)
	# Find RaceManager and PlayerSled
	await get_tree().process_frame
	race_manager = get_tree().root.find_child("RaceManager", true, false)
	player_sled = get_tree().root.find_child("PlayerSled", true, false)
	if race_manager:
		race_manager.race_finished.connect(_on_race_finished)

func _process(_delta: float) -> void:
	if not race_manager:
		return

	# Timer
	timer_label.text = race_manager.get_time_string()

	# Lap
	var lap_current = race_manager.current_lap + 1
	if race_manager.state == race_manager.RaceState.FINISHED:
		lap_current = race_manager.max_laps
	lap_label.text = "Lap %d / %d" % [mini(lap_current, race_manager.max_laps), race_manager.max_laps]

	# Speed
	if player_sled and player_sled.has_method("get_speed_kph"):
		speed_label.text = "%d km/h" % int(player_sled.get_speed_kph())
	else:
		speed_label.text = "0 km/h"

	# Checkpoint progress
	var tracker = race_manager.lap_tracker
	if tracker:
		var next_cp = tracker.next_checkpoint + 1
		var total_cp = tracker.total_checkpoints
		checkpoint_label.text = "CP %d / %d" % [mini(next_cp, total_cp), total_cp]

func _on_race_finished(final_time: float) -> void:
	finish_panel.visible = true
	var minutes := int(final_time) / 60
	var seconds := int(final_time) % 60
	var millis := int((final_time - int(final_time)) * 100)
	finish_time_label.text = "Finished!\n%02d:%02d.%02d" % [minutes, seconds, millis]

func _on_restart_pressed() -> void:
	if race_manager:
		race_manager.restart()
