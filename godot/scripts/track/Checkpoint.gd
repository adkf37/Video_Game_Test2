extends Area3D
## A single checkpoint trigger volume.
## When the player drives through, it notifies the LapTracker.

@export var checkpoint_index: int = 0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Checkpoints are monitoring-only, not monitored
	monitoring = true
	monitorable = false

func _on_body_entered(body: Node3D) -> void:
	if body.name == "PlayerSled" or body.is_in_group("player"):
		var tracker = _find_lap_tracker()
		if tracker:
			tracker.checkpoint_hit(checkpoint_index)

func _find_lap_tracker() -> Node:
	# Search up the tree for RaceManager, which holds the LapTracker reference
	var race_mgr = get_tree().root.find_child("RaceManager", true, false)
	if race_mgr and race_mgr.has_method("checkpoint_hit"):
		return race_mgr
	# Fallback: look for standalone LapTracker
	var tracker = get_tree().root.find_child("LapTracker", true, false)
	return tracker
