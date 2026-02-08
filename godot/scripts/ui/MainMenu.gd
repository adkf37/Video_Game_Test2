extends Control
## Main Menu — handles Play and Quit buttons.

func _ready() -> void:
	$CenterContainer/VBoxContainer/PlayButton.pressed.connect(_on_play_pressed)
	$CenterContainer/VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)

func _on_play_pressed() -> void:
	print("[MainMenu] Play pressed — loading race scene")
	GameState.change_state(GameState.State.RACING)
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")

func _on_quit_pressed() -> void:
	print("[MainMenu] Quit pressed")
	get_tree().quit()
