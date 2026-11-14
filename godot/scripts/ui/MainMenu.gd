extends Control
## Compatibility entry point for old editor bookmarks.
func _ready() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/main/Main.tscn")
