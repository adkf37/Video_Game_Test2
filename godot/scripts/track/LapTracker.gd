extends Node
## Tracks checkpoint progress for the player.
## Ensures checkpoints are hit in order before a lap counts.

signal checkpoint_passed(index: int)
signal lap_completed(lap_number: int)

var total_checkpoints: int = 0
var next_checkpoint: int = 0
var current_lap: int = 0

func setup(num_checkpoints: int) -> void:
	total_checkpoints = num_checkpoints
	next_checkpoint = 0
	current_lap = 0
	print("[LapTracker] Set up with %d checkpoints" % total_checkpoints)

func checkpoint_hit(index: int) -> void:
	if total_checkpoints == 0:
		return
	if index == next_checkpoint:
		next_checkpoint += 1
		checkpoint_passed.emit(index)
		print("[LapTracker] Checkpoint %d/%d hit" % [index + 1, total_checkpoints])
		# Check if all checkpoints passed → lap complete
		if next_checkpoint >= total_checkpoints:
			next_checkpoint = 0
			current_lap += 1
			lap_completed.emit(current_lap)
			print("[LapTracker] Lap %d completed!" % current_lap)

func reset() -> void:
	next_checkpoint = 0
	current_lap = 0
