extends CanvasLayer
## A responsive 1280x720 canvas. World stays visible behind menus.
const INK := Color("#153746")
const CREAM := Color("#fff8e7")
const MUTED := Color("#bed3d7")
const CORAL := Color("#ed8668")
var root: Control
var menu_panel: Control
var race_panel: Control
var split_panel: Control
var split_readouts: Array[Dictionary] = []
var pause_panel: Control
var results_panel: Control
var countdown_label: Label
var timer_label: Label
var lap_label: Label
var speed_label: Label
var boost_bar: ProgressBar
var boost_label: Label
var boost_hint: Label
var status_label: Label
var item_label: Label
var best_label: Label
var result_time: Label
var result_details: Label
var record_label: Label
var audio_label: Label
var toast: Label
var toast_remaining := 0.0
var last_state := -1
var position_label: Label
var leaderboard: Label
var result_heading: Label
var result_laps: Label
var standings_refresh := 0.0
var start_button: Button
var resume_button: Button
var again_button: Button
@onready var manager: Node = get_parent().get_node("RaceManager")
@onready var sled: Node3D = get_parent().get_node("PlayerSled")

func _ready() -> void:
	if GameState.mobile_mode:
		visible = false
		set_process(false)
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_menu()
	_build_race()
	_build_split()
	_build_pause()
	_build_results()
	manager.announcement.connect(_announce)
	manager.race_finished.connect(_finished)

func _label(parent: Node, text: String, pos: Vector2, font_size: int, color: Color = CREAM, dimensions: Vector2 = Vector2(600, 55)) -> Label:
	var label := Label.new()
	parent.add_child(label)
	label.position = pos
	label.size = dimensions
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if color == INK:
		label.add_theme_color_override("font_outline_color", Color(1, 0.98, 0.91, 0.9))
		label.add_theme_constant_override("outline_size", 4)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _style(color: Color, radius: int = 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.content_margin_left = 20
	style.content_margin_right = 20
	return style

func _panel(parent: Node, pos: Vector2, dimensions: Vector2, color: Color) -> Panel:
	var panel := Panel.new()
	parent.add_child(panel)
	panel.position = pos
	panel.size = dimensions
	panel.add_theme_stylebox_override("panel", _style(color))
	return panel

func _button(parent: Node, text: String, pos: Vector2, callback: Callable, primary: bool = true) -> Button:
	var button := Button.new()
	parent.add_child(button)
	button.position = pos
	button.size = Vector2(330, 52)
	button.text = text
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_color_override("font_color", INK if primary else CREAM)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_focus_color", INK if primary else CREAM)
	button.add_theme_stylebox_override("normal", _style(CORAL if primary else Color("#2a505c"), 8))
	button.add_theme_stylebox_override("hover", _style(Color("#ffd79b"), 8))
	button.add_theme_stylebox_override("pressed", _style(Color("#dfb77b"), 8))
	var focus := _style(Color(0, 0, 0, 0), 8)
	focus.set_border_width_all(2)
	focus.border_color = CREAM
	button.add_theme_stylebox_override("focus", focus)
	var click := "confirm" if primary else ("back" if text.begins_with("Back") else "select")
	button.pressed.connect(func(): GameState.play_ui(click))
	button.pressed.connect(callback)
	button.mouse_entered.connect(func(): GameState.play_ui("hover"))
	return button

func _group() -> Control:
	var control := Control.new()
	root.add_child(control)
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return control

func _build_menu() -> void:
	menu_panel = _group()
	_panel(menu_panel, Vector2(30, 24), Vector2(422, 672), Color(0.055, 0.15, 0.19, 0.95))
	_label(menu_panel, "THE GREAT DOGSLED TOUR", Vector2(65, 39), 13, CORAL)
	_label(menu_panel, "DOGSLED KART", Vector2(62, 78), 36, CREAM, Vector2(370, 65))
	_label(menu_panel, "Build your team. Share the trail.", Vector2(65, 132), 16, MUTED)
	_selector("RACE MODE", "race_mode", RaceCatalog.MODES, 187)
	_selector("TRACK", "course", RaceCatalog.COURSES, 252)
	_selector("DIFFICULTY", "difficulty", RaceCatalog.DIFFICULTIES, 317)
	var breeds: Array[String] = []
	for i in range(4):
		breeds.append("%s  /  %d dogs" % [RaceCatalog.BREEDS[i], RaceCatalog.TEAM_COUNTS[i]])
	_selector("PLAYER 1 DOGS" if GameState.race_mode == 1 else "DOG TEAM", "breed", breeds, 382)
	_selector("PLAYER 1 SLED" if GameState.race_mode == 1 else "SLED", "sled_style", RaceCatalog.SLEDS, 447)
	start_button = _button(menu_panel, "Race together    >" if GameState.race_mode == 1 else "Race the pack    >", Vector2(76, 511), manager.start)
	_label(menu_panel, menu_controls_text(), Vector2(65, 579), 14, MUTED, Vector2(365, 75))
	best_label = _label(menu_panel, "", Vector2(65, 663), 12, CORAL, Vector2(360, 25))
	_label(menu_panel, RaceCatalog.COURSES[GameState.course].to_upper(), Vector2(870, 44), 21, INK, Vector2(370, 40)).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label(menu_panel, "4 TEAMS / 3 LAPS / " + RaceCatalog.DIFFICULTIES[GameState.difficulty].to_upper(), Vector2(870, 80), 13, INK, Vector2(370, 40)).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if GameState.race_mode == 1:
		_panel(menu_panel, Vector2(840, 165), Vector2(410, 365), Color(0.055, 0.15, 0.19, 0.95))
		_label(menu_panel, "PLAYER 2  /  BOTTOM SCREEN", Vector2(865, 185), 17, Color("#5fcddd"))
		_selector("DOG TEAM", "breed2", breeds, 254, 865)
		_selector("SLED", "sled_style2", RaceCatalog.SLEDS, 329, 865)
		_label(menu_panel, "ARROWS steer / SLASH boost\nPERIOD drift / COMMA bone\nBACKSPACE recover / ENTER view\nSpace is unassigned. ESC pauses both.", Vector2(865, 393), 15, MUTED, Vector2(365, 115))
	else:
		_panel(menu_panel, Vector2(840, 165), Vector2(410, 385), Color(0.055, 0.15, 0.19, 0.95))
		_label(menu_panel, "SOLO CONTROLS", Vector2(865, 183), 22, CORAL, Vector2(360, 40))
		_label(menu_panel, "WASD / ARROWS", Vector2(865, 229), 23, CREAM, Vector2(360, 40))
		_label(menu_panel, "Drive, steer & brake", Vector2(865, 265), 15, MUTED, Vector2(360, 30))
		_label(menu_panel, "F   Boost        SHIFT   Drift", Vector2(865, 302), 18, CREAM, Vector2(360, 35))
		_label(menu_panel, "E   Throw Golden Bone", Vector2(865, 340), 18, CORAL, Vector2(360, 35))
		_label(menu_panel, "C   Chase / musher view", Vector2(865, 378), 18, CREAM, Vector2(360, 35))
		_label(menu_panel, "R   Recover (+3 seconds)", Vector2(865, 416), 18, CREAM, Vector2(360, 35))
		_label(menu_panel, "ESC  Pause    M  Mute    - +  Volume", Vector2(865, 454), 17, CREAM, Vector2(360, 35))
		_label(menu_panel, "Collect glowing bones along the trail.", Vector2(865, 502), 14, MUTED, Vector2(365, 30))
	_button(menu_panel, "Quit", Vector2(900, 620), func(): get_tree().quit(), false)

func _selector(caption: String, key: String, choices: Array, y: float, x: float = 65) -> void:
	_label(menu_panel, caption, Vector2(x, y - 23), 12, CORAL, Vector2(360, 27))
	var option := OptionButton.new()
	menu_panel.add_child(option)
	option.position = Vector2(x, y)
	option.size = Vector2(352, 39)
	option.add_theme_font_size_override("font_size", 18)
	option.add_theme_color_override("font_color", CREAM)
	option.add_theme_stylebox_override("normal", _style(Color("#2a505c"), 7))
	option.add_theme_stylebox_override("hover", _style(Color("#426673"), 7))
	option.add_theme_stylebox_override("pressed", _style(Color("#426673"), 7))
	for choice: String in choices:
		option.add_item(choice)
	option.select(GameState.get(key))
	option.mouse_entered.connect(func(): GameState.play_ui("hover"))
	option.item_selected.connect(func(index: int):
		GameState.play_ui("select")
		GameState.set_option(key, index)
		if key in ["course", "difficulty", "race_mode"]:
			get_tree().reload_current_scene()
		else:
			manager.apply_customization())

func _build_race() -> void:
	race_panel = _group()
	_panel(race_panel, Vector2(30, 28), Vector2(240, 114), Color(0.055, 0.15, 0.19, 0.88))
	_label(race_panel, RaceCatalog.COURSES[GameState.course].to_upper(), Vector2(50, 38), 13, CORAL)
	lap_label = _label(race_panel, "LAP  1 / 3", Vector2(48, 65), 32)
	_label(race_panel, "PACK RACE  /  " + RaceCatalog.DIFFICULTIES[GameState.difficulty].to_upper(), Vector2(50, 115), 10, MUTED)
	_panel(race_panel, Vector2(30, 158), Vector2(240, 170), Color(0.055, 0.15, 0.19, 0.88))
	_label(race_panel, "ON THE TRAIL", Vector2(50, 168), 12, CORAL)
	leaderboard = _label(race_panel, "", Vector2(50, 208), 18, CREAM, Vector2(210, 115))
	_panel(race_panel, Vector2(550, 48), Vector2(180, 85), Color(0.055, 0.15, 0.19, 0.88))
	position_label = _label(race_panel, "4 / 4", Vector2(550, 58), 40, CREAM, Vector2(180, 65))
	position_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel(race_panel, Vector2(980, 28), Vector2(270, 114), Color(0.055, 0.15, 0.19, 0.88))
	_label(race_panel, "TRAIL TIME", Vector2(1002, 38), 13, CORAL)
	timer_label = _label(race_panel, "00:00.00", Vector2(999, 65), 36)
	_panel(race_panel, Vector2(30, 550), Vector2(290, 138), Color(0.055, 0.15, 0.19, 0.95))
	speed_label = _label(race_panel, "0", Vector2(50, 550), 42)
	_label(race_panel, "KM/H", Vector2(159, 570), 13, MUTED)
	boost_label = _label(race_panel, "TURBO LEFT  100%", Vector2(50, 604), 17, CREAM, Vector2(255, 28))
	boost_bar = _boost_meter(race_panel, Vector2(50, 635), Vector2(250, 17))
	boost_hint = _label(race_panel, "HOLD F / Release to refill", Vector2(50, 657), 12, MUTED, Vector2(255, 24))
	item_label = _label(race_panel, "COLLECT A GOLDEN BONE", Vector2(350, 620), 16, INK, Vector2(580, 38))
	item_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label = _label(race_panel, "", Vector2(350, 555), 17, INK, Vector2(580, 38))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var map := Control.new()
	map.set_script(preload("res://scripts/ui/Minimap.gd"))
	map.track = get_parent().get_node("Track")
	map.sled = sled
	map.manager = manager
	race_panel.add_child(map)
	map.position = Vector2(1020, 490)
	map.size = Vector2(230, 198)
	_label(race_panel, "SHIFT drift   F boost   E throw bone   R recover   C view   ESC pause", Vector2(365, 665), 13, INK)
	countdown_label = _label(race_panel, "", Vector2(300, 230), 100, INK, Vector2(680, 160))
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast = _label(race_panel, "", Vector2(280, 177), 32, INK, Vector2(720, 60))
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	audio_label = _label(root, "", Vector2(440, 14), 12, INK, Vector2(400, 30))
	audio_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _build_pause() -> void:
	pause_panel = _group()
	_panel(pause_panel, Vector2.ZERO, Vector2(1280, 720), Color(0.04, 0.12, 0.17, 0.55))
	_panel(pause_panel, Vector2(410, 128), Vector2(460, 465), INK)
	_label(pause_panel, "TAKE A BREATHER", Vector2(470, 163), 15, CORAL)
	_label(pause_panel, "Trail paused", Vector2(470, 204), 37)
	_label(pause_panel, "Your team is ready when you are.", Vector2(470, 264), 16, MUTED)
	resume_button = _button(pause_panel, "Keep mushing", Vector2(475, 327), manager.resume)
	_button(pause_panel, "Start again", Vector2(475, 395), manager.restart, false)
	_button(pause_panel, "Back to basecamp", Vector2(475, 463), manager.menu, false)

func _build_results() -> void:
	results_panel = _group()
	_panel(results_panel, Vector2.ZERO, Vector2(1280, 720), Color(0.04, 0.12, 0.17, 0.4))
	_panel(results_panel, Vector2(390, 65), Vector2(500, 590), INK)
	record_label = _label(results_panel, "TRAIL COMPLETE", Vector2(442, 100), 17, CORAL)
	result_heading = _label(results_panel, "Good dogs. Great run.", Vector2(442, 145), 32)
	result_time = _label(results_panel, "", Vector2(442, 204), 54)
	_label(results_panel, "YOUR TIME  /  includes recovery penalties", Vector2(446, 280), 12, MUTED)
	result_details = _label(results_panel, "", Vector2(446, 307), 18, MUTED, Vector2(390, 133))
	result_laps = _label(results_panel, "", Vector2(446, 436), 12, MUTED, Vector2(390, 43))
	again_button = _button(results_panel, "One more run    >", Vector2(475, 487), manager.restart)
	_button(results_panel, "Back to basecamp", Vector2(475, 555), manager.menu, false)

func _announce(message: String) -> void:
	toast.text = message
	toast_remaining = 2.2

func _finished(total: float) -> void:
	result_time.text = GameState.time_text(total)
	record_label.text = "FINISHED %d / 4" % manager.player_finish_place
	if manager.new_record:
		record_label.text += "   /   PERSONAL BEST"
	result_heading.text = "You led the pack!" if manager.player_finish_place == 1 else "Good dogs. Great race."
	result_laps.text = "LAPS  "
	for lap: float in manager.lap_times:
		result_laps.text += GameState.time_text(lap) + "   "
	result_laps.text += "\nBEST  " + (GameState.time_text(GameState.best_time) if GameState.best_time > 0 else "--:--.--")
	if GameState.save_error:
		result_laps.text += "  (save failed)"
	if GameState.race_mode == 1:
		record_label.text = "LOCAL DUEL COMPLETE"
		result_heading.text = "Player %d wins the duel!" % (1 if manager.finish_order.find(manager.players[0]) < manager.finish_order.find(manager.players[1]) else 2)
		result_time.text = "P1  " + GameState.time_text(manager.player_times[0])
		result_time.add_theme_font_size_override("font_size", 38)
		result_laps.text = "P2 PERSONAL TIME  " + GameState.time_text(manager.player_times[1]) + "\nSolo records are kept separate."
	_refresh_standings()

func _refresh_standings() -> void:
	var rows: Array[Dictionary] = manager.standings()
	leaderboard.text = ""
	result_details.text = ""
	for i in range(rows.size()):
		var row := rows[i]
		var name_text: String = row.name.to_upper() + ("  <" if row.player else "")
		leaderboard.text += "%d   %s%s\n" % [i + 1, name_text, "  FIN" if row.finished else ""]
		var time_text: String = GameState.time_text(row.time) if row.finished else "Racing..."
		if row.estimated:
			time_text += " est."
		result_details.text += "%d   %-10s  %s\n" % [i + 1, row.name.to_upper(), time_text]
		if row.player_index == 0:
			position_label.text = "%d / 4" % (i + 1)

func _process(delta: float) -> void:
	standings_refresh -= delta
	if standings_refresh <= 0:
		_refresh_standings()
		standings_refresh = 0.12
	menu_panel.visible = manager.state == manager.RaceState.MENU
	pause_panel.visible = manager.state == manager.RaceState.PAUSED
	results_panel.visible = manager.state == manager.RaceState.FINISHED
	var racing_visible := not menu_panel.visible and not results_panel.visible and not pause_panel.visible
	race_panel.visible = racing_visible and GameState.race_mode == 0
	split_panel.visible = racing_visible and GameState.race_mode == 1
	if split_panel.visible:
		_update_split()
	if manager.state != last_state:
		last_state = manager.state
		if manager.state != manager.RaceState.RACING:
			toast_remaining = 0
		if menu_panel.visible:
			start_button.grab_focus()
		elif pause_panel.visible:
			resume_button.grab_focus()
		elif results_panel.visible:
			again_button.grab_focus()
		else:
			var focused := root.get_viewport().gui_get_focus_owner()
			if focused:
				focused.release_focus()
	best_label.text = "LOCAL DUEL / independent teams and cameras" if GameState.race_mode == 1 else ("BEST  " + GameState.time_text(GameState.best_time) if GameState.best_time > 0 else "Your first trail record awaits.")
	timer_label.text = GameState.time_text(manager.race_time)
	lap_label.text = "LAP  %d / 3" % mini(manager.current_lap + 1, 3)
	speed_label.text = "%d" % roundi(sled.get_speed_kph())
	_update_boost(boost_bar, boost_label, boost_hint, sled, "F")
	item_label.text = sled.item_hint()
	countdown_label.text = str(clampi(ceili(manager.countdown), 1, 3)) if manager.state == manager.RaceState.COUNTDOWN else ""
	audio_label.text = ("M  /  SOUND OFF" if GameState.muted else "M  /  SOUND ON") + "     -  +  /  VOLUME %d%%" % roundi(GameState.volume * 100)
	if not pause_panel.visible:
		toast_remaining -= delta
	toast.visible = toast_remaining > 0
	status_label.text = ""
	if manager.state == manager.RaceState.RACING:
		var forward := -sled.global_basis.z
		var route_forward: Vector3 = -sled.track.frame_at(sled.route_progress).basis.z
		if forward.dot(route_forward) < -0.3 and sled.get_speed_kph() > 5:
			status_label.text = "WRONG WAY  /  turn around"
		elif sled.offroad:
			status_label.text = "FIRST CUT  /  light slowdown" if sled.offroad_cut == 1 else "SECOND CUT  /  deep slowdown"
		elif sled.boosting:
			status_label.text = "TURBO ON"
		elif sled.drifting:
			status_label.text = "CARVING"

func _build_split() -> void:
	split_panel = _group()
	var divider := ColorRect.new()
	split_panel.add_child(divider)
	divider.position = Vector2(0, 358)
	divider.size = Vector2(1280, 4)
	divider.color = INK
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in range(2):
		var y := i * 360.0
		var color := CORAL if i == 0 else Color("#5fcddd")
		_panel(split_panel, Vector2(18, y + 14), Vector2(240, 90), Color(0.055, 0.15, 0.19, 0.88))
		_label(split_panel, "PLAYER %d" % (i + 1), Vector2(35, y + 20), 14, color)
		var lap := _label(split_panel, "", Vector2(35, y + 47), 25, CREAM, Vector2(215, 40))
		_panel(split_panel, Vector2(1040, y + 14), Vector2(222, 90), Color(0.055, 0.15, 0.19, 0.88))
		var time := _label(split_panel, "", Vector2(1057, y + 25), 27, CREAM, Vector2(205, 40))
		var view := _label(split_panel, "", Vector2(1057, y + 66), 13, color, Vector2(205, 30))
		_panel(split_panel, Vector2(18, y + 245), Vector2(285, 103), Color(0.055, 0.15, 0.19, 0.95))
		var speed := _label(split_panel, "", Vector2(35, y + 249), 23, CREAM, Vector2(250, 31))
		var energy := _label(split_panel, "", Vector2(35, y + 280), 15, CREAM, Vector2(255, 24))
		var boost := _boost_meter(split_panel, Vector2(35, y + 309), Vector2(250, 14))
		var hint := _label(split_panel, "", Vector2(35, y + 326), 11, MUTED, Vector2(255, 22))
		var status := _label(split_panel, "", Vector2(320, y + 291), 16, INK, Vector2(620, 28))
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var controls := "WASD / F boost / SHIFT drift / E throw bone / R recover / C view" if i == 0 else "ARROWS / SLASH boost / PERIOD drift / COMMA bone / BACKSPACE recover / ENTER view"
		_label(split_panel, controls, Vector2(320, y + 327), 12, INK, Vector2(930, 25))
		var message := _label(split_panel, "", Vector2(290, y + 113), 52, INK, Vector2(700, 100))
		message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		split_readouts.append({"lap": lap, "time": time, "view": view, "speed": speed, "boost": boost, "energy": energy, "hint": hint, "status": status, "message": message})

func _update_split() -> void:
	for i in range(manager.players.size()):
		var player: Node = manager.players[i]
		var fields := split_readouts[i]
		var done: bool = player in manager.finish_order
		fields.lap.text = "%d / 4    LAP %d / 3" % [manager.player_position(i), mini(manager.player_trackers[i].current_lap + 1, 3)]
		fields.time.text = GameState.time_text(manager.player_times[i])
		fields.view.text = "MUSHER VIEW" if GameState.camera_modes[i] == 1 else "CHASE VIEW"
		fields.speed.text = "%d KM/H" % roundi(player.get_speed_kph())
		_update_boost(fields.boost, fields.energy, fields.hint, player, "F" if i == 0 else "SLASH")
		fields.status.text = player.item_hint()
		if player.offroad:
			fields.status.text += "  /  " + ("FIRST CUT" if player.offroad_cut == 1 else "SECOND CUT")
		fields.message.add_theme_font_size_override("font_size", 25 if done else 72)
		fields.message.text = "FINISHED / Other player still racing" if done else (str(clampi(ceili(manager.countdown), 1, 3)) if manager.state == manager.RaceState.COUNTDOWN else "")

func menu_controls_text() -> String:
	if GameState.race_mode == 1:
		return "P1  WASD / F boost / SHIFT drift\nE bone / R recover / C view\nESC pauses both / M sound"
	return "SOLO RACE / three computer rivals\nCollect a bone, then press E to throw.\nDistract a rival's dogs for 1 second."

func _boost_meter(parent: Control, pos: Vector2, dimensions: Vector2) -> ProgressBar:
	var bar := ProgressBar.new()
	parent.add_child(bar)
	bar.position = pos
	bar.show_percentage = false
	for part in ["background", "fill"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("#071e2a") if part == "background" else Color("#59d6ee")
		style.set_corner_radius_all(3)
		style.content_margin_left = 0
		style.content_margin_right = 0
		style.content_margin_top = 0
		style.content_margin_bottom = 0
		bar.add_theme_stylebox_override(part, style)
	# Set size after hiding the built-in percentage so its font cannot enlarge it.
	bar.size = dimensions
	return bar

func _update_boost(bar: ProgressBar, label: Label, hint: Label, player: Node, key: String) -> void:
	var remaining := roundi(player.boost_energy)
	bar.value = player.boost_energy
	label.text = "TURBO LEFT  %d%%" % remaining
	var color := Color("#ffc857") if remaining <= 25 else Color("#59d6ee")
	bar.get_theme_stylebox("fill").bg_color = color
	label.add_theme_color_override("font_color", color)
	if player.boosting:
		hint.text = "USING TURBO / Release to refill"
	elif player.boost_latched:
		hint.text = "RELEASE %s / Refill turbo" % key
	elif player.offroad:
		hint.text = "Return to the track to use turbo"
	elif remaining < 100:
		hint.text = "REFILLING / Hold %s for turbo" % key
	else:
		hint.text = "HOLD %s / Release to refill" % key
