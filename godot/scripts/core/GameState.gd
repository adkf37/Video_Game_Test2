extends Node
## Global game state — autoload singleton.
## Tracks current game phase (menu, racing, paused, results).

enum State { MENU, RACING, PAUSED, RESULTS }

var current_state: State = State.MENU

func _ready() -> void:
	print("[GameState] Autoload initialized")

func change_state(new_state: State) -> void:
	var old_name = State.keys()[current_state]
	current_state = new_state
	var new_name = State.keys()[new_state]
	print("[GameState] %s → %s" % [old_name, new_name])
