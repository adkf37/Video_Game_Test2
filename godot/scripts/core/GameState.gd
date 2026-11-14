extends Node
## Offline personal best, separate from any older prototype saves.
const SAVE_PATH := "user://alpine_time_trial_v1.cfg"
var course := 0
var difficulty := 1
var breed := 0
var sled_style := 0
var save_path := SAVE_PATH
var best_time := 0.0
var best_lap := 0.0
var muted := false
var save_error := false
var practice_run := false

func _ready() -> void:
	var config := ConfigFile.new()
	if config.load(save_path) == OK:
		course = clampi(int(config.get_value("garage", "course", 0)), 0, 2)
		difficulty = clampi(int(config.get_value("garage", "difficulty", 1)), 0, 2)
		breed = clampi(int(config.get_value("garage", "breed", 0)), 0, 3)
		sled_style = clampi(int(config.get_value("garage", "sled_style", 0)), 0, 3)
	load_records()
	_setup_input()

func load_records() -> void:
	best_time = 0.0
	best_lap = 0.0
	var config := ConfigFile.new()
	if config.load(save_path) == OK:
		best_time = maxf(0.0, float(config.get_value(record_section(), "best_time", 0.0)))
		best_lap = maxf(0.0, float(config.get_value(record_section(), "best_lap", 0.0)))
		muted = bool(config.get_value("audio", "muted", false))

func _setup_input() -> void:
	var bindings := {"drift": KEY_SHIFT, "boost": KEY_SPACE, "recover": KEY_R, "pause": KEY_ESCAPE, "mute": KEY_M, "whip": KEY_E}
	for action: String in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var key := InputEventKey.new()
		key.physical_keycode = bindings[action]
		InputMap.action_add_event(action, key)
	# Virtual/accessibility keyboards may send logical keys without scan codes.
	for action in ["move_forward", "move_back", "turn_left", "turn_right", "drift", "boost", "recover", "pause", "mute", "whip"]:
		for event in InputMap.action_get_events(action):
			if event is InputEventKey and event.physical_keycode != 0:
				var logical := InputEventKey.new()
				logical.keycode = event.physical_keycode
				if not InputMap.action_has_event(action, logical):
					InputMap.action_add_event(action, logical)
	for binding: Array in [["turn_left", JOY_AXIS_LEFT_X, -1.0], ["turn_right", JOY_AXIS_LEFT_X, 1.0], ["move_forward", JOY_AXIS_TRIGGER_RIGHT, 1.0], ["move_back", JOY_AXIS_TRIGGER_LEFT, 1.0]]:
		var event := InputEventJoypadMotion.new()
		event.axis = binding[1]
		event.axis_value = binding[2]
		InputMap.action_add_event(binding[0], event)
	for binding: Array in [["boost", JOY_BUTTON_A], ["drift", JOY_BUTTON_LEFT_SHOULDER], ["recover", JOY_BUTTON_Y], ["pause", JOY_BUTTON_START], ["whip", JOY_BUTTON_X]]:
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
	config.set_value(record_section(), "best_time", best_time)
	config.set_value(record_section(), "best_lap", best_lap)
	_write_preferences(config)
	save_error = config.save(save_path) != OK

func time_text(seconds: float) -> String:
	return "%02d:%05.2f" % [int(seconds) / 60, fmod(seconds, 60.0)]

func record_section() -> String:
	return "tour_v2_%d_%d" % [course, difficulty]

func _write_preferences(config: ConfigFile) -> void:
	config.set_value("audio", "muted", muted)
	for key in ["course", "difficulty", "breed", "sled_style"]:
		config.set_value("garage", key, get(key))

func set_option(key: String, value: int) -> void:
	if key not in ["course", "difficulty", "breed", "sled_style"]:
		return
	set(key, clampi(value, 0, 2 if key in ["course", "difficulty"] else 3))
	if not practice_run:
		var config := ConfigFile.new()
		config.load(save_path)
		_write_preferences(config)
		save_error = config.save(save_path) != OK
	load_records()
