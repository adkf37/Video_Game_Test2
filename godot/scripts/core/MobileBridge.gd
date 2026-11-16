extends Node
## Mobile-only same-origin web controller. Desktop input/UI remain independent.
var manager: Node
var adapter: JavaScriptObject
var callback: JavaScriptObject
var steer := 0.0
var boost := false
var brake := false
var drift := false
var throw_requested := false
var since_input := 10.0
var publish_wait := 0.0
var toast := ""
var toast_time := 0.0
var ready_sent := false
@onready var settings: Node = get_tree().root.get_node("GameState")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.has_feature("web"):
		adapter = JavaScriptBridge.get_interface("mobileEngine")
		callback = JavaScriptBridge.create_callback(_from_web)
		if adapter:
			adapter.onCommand = callback

func _from_web(arguments: Array) -> void:
	if arguments.is_empty() or not arguments[0] is String:
		return
	var data = JSON.parse_string(arguments[0])
	if data is Dictionary:
		command(data)

func command(data: Dictionary) -> void:
	if not manager or not is_instance_valid(manager):
		return
	match data.get("type", ""):
		"input":
			var value: float = float(data.get("steer", 0))
			steer = clampf(value, -1, 1) if is_finite(value) else 0.0
			boost = data.get("boost", false) == true
			brake = data.get("brake", false) == true
			drift = data.get("drift", false) == true
			since_input = 0.0
		"start":
			if manager.state in [manager.RaceState.MENU, manager.RaceState.FINISHED]:
				clear_controls()
				manager.start()
		"pause": pause()
		"resume":
			if manager.state == manager.RaceState.PAUSED:
				clear_controls()
				manager.resume()
		"throw":
			if manager.state == manager.RaceState.RACING:
				throw_requested = true
		"recover": manager.recover()
		"camera": settings.camera_modes[0] = 1 - settings.camera_modes[0]
		"volume": settings.change_volume(clampi(int(data.get("steps", 0)), -1, 1))
		"mute":
			settings.muted = not settings.muted
			if not settings.practice_run:
				settings.save()

func clear_controls() -> void:
	steer = 0
	boost = false
	brake = false
	drift = false
	throw_requested = false
	since_input = 10

func pause() -> void:
	clear_controls()
	if manager.state in [manager.RaceState.RACING, manager.RaceState.COUNTDOWN]:
		manager.resume_state = manager.state
		manager.state = manager.RaceState.PAUSED
		get_tree().paused = true

func controls() -> Dictionary:
	var fresh := since_input < 0.7
	var throwing := throw_requested and fresh
	throw_requested = false
	return {"throttle": (-1.0 if brake else 1.0) if fresh else 0.0,
		"steer": steer if fresh else 0.0, "boost": boost and fresh,
		"drift": drift and fresh, "throw_item": throwing}

func _process(delta: float) -> void:
	if not is_instance_valid(manager):
		manager = get_tree().get_first_node_in_group("race")
		ready_sent = false
	if not manager or not manager.items or manager.players.is_empty():
		return
	if not ready_sent:
		ready_sent = true
		manager.announcement.connect(func(text: String): toast = text; toast_time = 2.4)
		var scene: Node = manager.get_parent()
		scene.get_node("Sun").shadow_enabled = false
		get_viewport().msaa_3d = Viewport.MSAA_DISABLED
		# The mobile HTML adapter caps rendering DPR; expand to the phone's aspect.
		if OS.has_feature("web"):
			get_tree().root.content_scale_size = Vector2i(960, 540)
			get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
			get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	since_input += delta
	if since_input > 1.5 and manager.state in [manager.RaceState.RACING, manager.RaceState.COUNTDOWN]:
		pause()
	toast_time = maxf(0, toast_time - delta)
	publish_wait -= delta
	if publish_wait <= 0:
		publish_wait = 0.10
		if adapter:
			adapter.send(JSON.stringify(snapshot()))

func snapshot() -> Dictionary:
	var player: Node = manager.players[0]
	var target: Node = manager.items.target_for(player) if player.has_bone else null
	var rows: Array = []
	if manager.state == manager.RaceState.FINISHED:
		for row in manager.standings():
			rows.append({"name": row.name, "time": settings.time_text(row.time), "estimated": row.estimated})
	return {"course": settings.course, "difficulty": settings.difficulty,
		"breed": settings.breed, "sled_style": settings.sled_style, "volume": settings.volume,
		"best_time": settings.time_text(settings.best_time) if settings.best_time > 0 else "",
		"ready": true, "state": manager.state, "speed": roundi(player.get_speed_kph()),
		"lap": mini(manager.current_lap + 1, manager.max_laps), "laps": manager.max_laps,
		"place": manager.player_position(), "time": settings.time_text(manager.race_time),
		"boost": roundi(player.boost_energy), "bone": player.has_bone, "target": target != null,
		"countdown": clampi(ceili(manager.countdown), 1, 3), "muted": settings.muted,
		"chasing": player.distraction_time, "stunned": player.hazard_time,
		"toast": toast if toast_time > 0 else "", "results": rows,
		"camera": settings.camera_modes[0], "steer": steer, "fps": Engine.get_frames_per_second()}
