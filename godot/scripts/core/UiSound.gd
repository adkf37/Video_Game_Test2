extends Node
## Menu sounds on a persistent node, so they finish even when a choice reloads the scene.
const SOUNDS := {
	"hover": preload("res://assets/audio/ui_hover.ogg"), "select": preload("res://assets/audio/ui_select.ogg"),
	"confirm": preload("res://assets/audio/ui_confirm.ogg"), "back": preload("res://assets/audio/ui_back.ogg"),
	"toggle": preload("res://assets/audio/ui_toggle.ogg"), "open": preload("res://assets/audio/ui_open.ogg"),
	"close": preload("res://assets/audio/ui_close.ogg")}
var players: Array[AudioStreamPlayer] = []
var enabled := DisplayServer.get_name() != "headless"
var play_count := 0
var last_hover := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(4):
		var player := AudioStreamPlayer.new()
		add_child(player)
		players.append(player)

func play(kind: String) -> void:
	if GameState.muted or not SOUNDS.has(kind):
		return
	if kind == "hover":
		var now := Time.get_ticks_msec()
		if now - last_hover < 60:
			return
		last_hover = now
	play_count += 1
	if not enabled:
		return
	var selected := players[0]
	for player in players:
		if not player.playing:
			selected = player
			break
	selected.stream = SOUNDS[kind]
	selected.volume_db = -14.0 if kind == "hover" else -7.0
	selected.play()
