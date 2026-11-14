extends Node
## Offline personal best, separate from any older prototype saves.
const SAVE_PATH := "user://alpine_time_trial_v1.cfg"
var course := 0
var difficulty := 1
var breed := 0
var sled_style := 0
var race_mode := 0
var breed2 := 1
var sled_style2 := 3
var camera_modes := [0, 0]
var save_path := SAVE_PATH
var best_time := 0.0
var best_lap := 0.0
var muted := false
var save_error := false
var practice_run := false

func _ready() -> void:
	var config := ConfigFile.new()
	if config.load(save_path) == OK:
		course = clampi(int(config.get_value("garage", "course", 0)), 0, RaceCatalog.COURSES.size() - 1)
		difficulty = clampi(int(config.get_value("garage", "difficulty", 1)), 0, 2)
		breed = clampi(int(config.get_value("garage", "breed", 0)), 0, 3)
		sled_style = clampi(int(config.get_value("garage", "sled_style", 0)), 0, 3)
		for key in ["race_mode", "breed2", "sled_style2"]:
			set(key, clampi(int(config.get_value("garage", key, get(key))), 0, 1 if key == "race_mode" else 3))
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
	var p1 := {"move_forward": KEY_W, "move_back": KEY_S, "turn_left": KEY_A, "turn_right": KEY_D,
		"drift": KEY_SHIFT, "boost": KEY_F, "whip": KEY_E, "recover": KEY_R, "camera": KEY_C}
	var p2 := {"move_forward": KEY_UP, "move_back": KEY_DOWN, "turn_left": KEY_LEFT, "turn_right": KEY_RIGHT,
		"drift": KEY_PERIOD, "boost": KEY_SLASH, "whip": KEY_COMMA, "recover": KEY_BACKSPACE, "camera": KEY_ENTER}
	for prefix: String in ["", "p1_", "p2_"]:
		var bindings: Dictionary = p2 if prefix == "p2_" else p1
		for action: String in bindings:
			var name := prefix + action
			if not InputMap.has_action(name):
				InputMap.add_action(name)
			InputMap.action_erase_events(name)
			_bind_key(name, bindings[action])
		if prefix == "":
			for action in ["move_forward", "move_back", "turn_left", "turn_right"]:
				_bind_key(action, p2[action])
		var device := 1 if prefix == "p2_" else 0
		for binding: Array in [["turn_left", JOY_AXIS_LEFT_X, -1.0], ["turn_right", JOY_AXIS_LEFT_X, 1.0], ["move_forward", JOY_AXIS_TRIGGER_RIGHT, 1.0], ["move_back", JOY_AXIS_TRIGGER_LEFT, 1.0]]:
			var event := InputEventJoypadMotion.new()
			event.device = device
			event.axis = binding[1]
			event.axis_value = binding[2]
			InputMap.action_add_event(prefix + binding[0], event)
		for binding: Array in [["boost", JOY_BUTTON_A], ["drift", JOY_BUTTON_LEFT_SHOULDER], ["recover", JOY_BUTTON_Y], ["whip", JOY_BUTTON_X], ["camera", JOY_BUTTON_RIGHT_SHOULDER]]:
			var event := InputEventJoypadButton.new()
			event.device = device
			event.button_index = binding[1]
			InputMap.action_add_event(prefix + binding[0], event)
	for binding: Array in [["pause", KEY_ESCAPE], ["mute", KEY_M]]:
		if not InputMap.has_action(binding[0]):
			InputMap.add_action(binding[0])
		InputMap.action_erase_events(binding[0])
		_bind_key(binding[0], binding[1])
	var pause_button := InputEventJoypadButton.new()
	pause_button.button_index = JOY_BUTTON_START
	pause_button.device = -1
	InputMap.action_add_event("pause", pause_button)

func _bind_key(action: String, code: int) -> void:
	# Support both physical keyboard scan codes and virtual keyboard events.
	var physical := InputEventKey.new()
	physical.physical_keycode = code
	InputMap.action_add_event(action, physical)
	var logical := InputEventKey.new()
	logical.keycode = code
	InputMap.action_add_event(action, logical)

func record_run(total: float, lap: float) -> bool:
	if practice_run or race_mode == 1:
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
	return "tour_v3_%d_%d" % [course, difficulty]

func _write_preferences(config: ConfigFile) -> void:
	config.set_value("audio", "muted", muted)
	for key in ["course", "difficulty", "breed", "sled_style", "race_mode", "breed2", "sled_style2"]:
		config.set_value("garage", key, get(key))

func set_option(key: String, value: int) -> void:
	if key not in ["course", "difficulty", "breed", "sled_style", "race_mode", "breed2", "sled_style2"]:
		return
	var maximum := 1 if key == "race_mode" else (2 if key == "difficulty" else 3)
	set(key, clampi(value, 0, maximum))
	if not practice_run:
		var config := ConfigFile.new()
		config.load(save_path)
		_write_preferences(config)
		save_error = config.save(save_path) != OK
	load_records()
