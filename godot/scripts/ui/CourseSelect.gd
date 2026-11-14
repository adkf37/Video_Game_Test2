extends Control
## This milestone ships one complete trail; old selection scene opens basecamp.
func _ready() -> void:
	get_tree().change_scene_to_file.call_deferred("res://scenes/main/Main.tscn")
