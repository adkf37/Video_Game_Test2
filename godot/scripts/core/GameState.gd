extends Node
## Offline personal best, separate from any older prototype saves.
const SAVE_PATH := "user://alpine_time_trial_v1.cfg"
const RECORD_SECTION := "alpine_pack"
var save_path := SAVE_PATH
var best_time := 0.0
var best_lap := 0.0
var muted := false
var save_error := false
var practice_run := false

func _ready() -> void:
	load_records()
	_setup_input()

func load_records() -> void:
	best_time = 0.0
	best_lap = 0.0
	var config := ConfigFile.new()
	if config.load(save_path) == OK:
		best_time = maxf(0.0, float(config.get_value(RECORD_SECTION, "best_time", 0.0)))
		best_lap = maxf(0.0, float(config.get_value(RECORD_SECTION, "best_lap", 0.0)))
		muted = bool(config.get_value("audio", "muted", false))

func _setup_input() -> void:
	var bindings := {"drift": KEY_SHIFT, "boost": KEY_SPACE, "recover": KEY_R, "pause": KEY_ESCAPE, "mute": KEY_M}
	for action: String in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var key := InputEventKey.new()
		key.physical_keycode = bindings[action]
		InputMap.action_add_event(action, key)
	for binding: Array in [["turn_left", JOY_AXIS_LEFT_X, -1.0], ["turn_right", JOY_AXIS_LEFT_X, 1.0], ["move_forward", JOY_AXIS_TRIGGER_RIGHT, 1.0], ["move_back", JOY_AXIS_TRIGGER_LEFT, 1.0]]:
		var event := InputEventJoypadMotion.new()
		event.axis = binding[1]
		event.axis_value = binding[2]
		InputMap.action_add_event(binding[0], event)
	for binding: Array in [["boost", JOY_BUTTON_A], ["drift", JOY_BUTTON_LEFT_SHOULDER], ["recover", JOY_BUTTON_Y], ["pause", JOY_BUTTON_START]]:
		var event := InputEventJoypadButton.new()
		event.button_index = binding[1]
		InputMap.action_add_event(binding[0], event)

func record_run(total: float, lap: float) -> bool:
	if practice_run:
		return false
	var record := best_time <= 0.0 or total < best_time
	if record:
		best_time = total
	if best_lap <= 0.0 or lap < best_lap:
		best_lap = lap
	save()
	return record

func save() -> void:
	var config := ConfigFile.new()
	# Keep the original solo records and audio preference in the same file.
	config.load(save_path)
	config.set_value(RECORD_SECTION, "best_time", best_time)
	config.set_value(RECORD_SECTION, "best_lap", best_lap)
	config.set_value("audio", "muted", muted)
	save_error = config.save(save_path) != OK

func time_text(seconds: float) -> String:
	return "%02d:%05.2f" % [int(seconds) / 60, fmod(seconds, 60.0)]
