extends CanvasLayer
## A responsive 1280x720 canvas. World stays visible behind menus.
const INK := Color("#153746")
const CREAM := Color("#fff8e7")
const MUTED := Color("#bed3d7")
const CORAL := Color("#ed8668")
var root: Control
var menu_panel: Control
var race_panel: Control
var pause_panel: Control
var results_panel: Control
var countdown_label: Label
var timer_label: Label
var lap_label: Label
var speed_label: Label
var boost_bar: ProgressBar
var status_label: Label
var whip_label: Label
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
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_menu()
	_build_race()
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
	button.pressed.connect(callback)
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
	_label(menu_panel, "DOGSLED KART", Vector2(62, 86), 36, CREAM, Vector2(370, 65))
	_label(menu_panel, "Build your team. Take on the pack.", Vector2(65, 145), 16, MUTED)
	_selector("TRACK", "course", RaceCatalog.COURSES, 211)
	_selector("DIFFICULTY", "difficulty", RaceCatalog.DIFFICULTIES, 292)
	var breeds: Array[String] = []
	for i in range(4):
		breeds.append("%s  /  %d dogs" % [RaceCatalog.BREEDS[i], RaceCatalog.TEAM_COUNTS[i]])
	_selector("DOG TEAM", "breed", breeds, 373)
	_selector("SLED", "sled_style", RaceCatalog.SLEDS, 454)
	start_button = _button(menu_panel, "Race the pack    >", Vector2(76, 535), manager.start)
	_label(menu_panel, "WASD drive   SHIFT drift   SPACE boost\nE whip   R recover   ESC pause", Vector2(65, 602), 14, MUTED, Vector2(365, 60))
	best_label = _label(menu_panel, "", Vector2(65, 661), 12, CORAL, Vector2(360, 25))
	_label(menu_panel, RaceCatalog.COURSES[GameState.course].to_upper(), Vector2(870, 44), 21, INK, Vector2(370, 40)).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label(menu_panel, "4 TEAMS / 3 LAPS / " + RaceCatalog.DIFFICULTIES[GameState.difficulty].to_upper(), Vector2(870, 80), 13, INK, Vector2(370, 40)).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_button(menu_panel, "Quit", Vector2(900, 620), func(): get_tree().quit(), false)

func _selector(caption: String, key: String, choices: Array, y: float) -> void:
	_label(menu_panel, caption, Vector2(65, y - 32), 12, CORAL, Vector2(360, 27))
	var option := OptionButton.new()
	menu_panel.add_child(option)
	option.position = Vector2(65, y)
	option.size = Vector2(352, 43)
	option.add_theme_font_size_override("font_size", 18)
	option.add_theme_color_override("font_color", CREAM)
	option.add_theme_stylebox_override("normal", _style(Color("#2a505c"), 7))
	option.add_theme_stylebox_override("hover", _style(Color("#426673"), 7))
	option.add_theme_stylebox_override("pressed", _style(Color("#426673"), 7))
	for choice: String in choices:
		option.add_item(choice)
	option.select(GameState.get(key))
	option.item_selected.connect(func(index: int):
		GameState.set_option(key, index)
		if key in ["course", "difficulty"]:
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
	_panel(race_panel, Vector2(30, 560), Vector2(270, 128), Color(0.055, 0.15, 0.19, 0.88))
	speed_label = _label(race_panel, "0", Vector2(50, 561), 46)
	_label(race_panel, "KM/H", Vector2(159, 585), 13, MUTED)
	_label(race_panel, "MUSH", Vector2(50, 638), 12, CORAL)
	boost_bar = ProgressBar.new()
	race_panel.add_child(boost_bar)
	boost_bar.position = Vector2(113, 649)
	boost_bar.size = Vector2(163, 9)
	boost_bar.show_percentage = false
	boost_bar.add_theme_stylebox_override("background", _style(Color("#3b5f6c"), 4))
	boost_bar.add_theme_stylebox_override("fill", _style(CORAL, 4))
	whip_label = _label(race_panel, "E  /  WHIP READY", Vector2(350, 620), 16, INK, Vector2(580, 38))
	whip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
	_label(race_panel, "SHIFT drift   SPACE boost   E whip   R recover   ESC pause", Vector2(365, 665), 13, INK)
	countdown_label = _label(race_panel, "", Vector2(300, 230), 100, INK, Vector2(680, 160))
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast = _label(race_panel, "", Vector2(280, 177), 32, INK, Vector2(720, 60))
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	audio_label = _label(root, "", Vector2(510, 14), 12, INK, Vector2(260, 30))
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
	_refresh_standings()

func _refresh_standings() -> void:
	var rows: Array[Dictionary] = manager.standings()
	leaderboard.text = ""
	result_details.text = ""
	for i in range(rows.size()):
		var row := rows[i]
		var name_text: String = row.name.to_upper() + ("  <" if row.player else "")
		leaderboard.text += "%d   %s%s\n" % [i + 1, name_text, "  FIN" if row.finished else ""]
		result_details.text += "%d   %-10s  %s\n" % [i + 1, row.name.to_upper(), GameState.time_text(row.time) if row.finished else "Racing..."]
		if row.player:
			position_label.text = "%d / 4" % (i + 1)

func _process(delta: float) -> void:
	standings_refresh -= delta
	if standings_refresh <= 0:
		_refresh_standings()
		standings_refresh = 0.12
	menu_panel.visible = manager.state == manager.RaceState.MENU
	pause_panel.visible = manager.state == manager.RaceState.PAUSED
	results_panel.visible = manager.state == manager.RaceState.FINISHED
	race_panel.visible = not menu_panel.visible and not results_panel.visible and not pause_panel.visible
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
	best_label.text = "BEST  " + GameState.time_text(GameState.best_time) if GameState.best_time > 0 else "Your first trail record awaits."
	timer_label.text = GameState.time_text(manager.race_time)
	lap_label.text = "LAP  %d / 3" % mini(manager.current_lap + 1, 3)
	speed_label.text = "%d" % roundi(sled.get_speed_kph())
	boost_bar.value = sled.boost_energy
	whip_label.text = "E  /  WHIP READY" if sled.whip_cooldown <= 0 else "WHIP RECHARGING  %.1fs" % sled.whip_cooldown
	countdown_label.text = str(clampi(ceili(manager.countdown), 1, 3)) if manager.state == manager.RaceState.COUNTDOWN else ""
	audio_label.text = "M  /  SOUND OFF" if GameState.muted else "M  /  SOUND ON"
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
			status_label.text = "OFF TRAIL  /  heavy slowdown"
		elif sled.boosting:
			status_label.text = "MUSH!"
		elif sled.drifting:
			status_label.text = "CARVING"
