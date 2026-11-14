extends Node
## Finish is checkpoint zero; a lap needs every sector then zero.
signal checkpoint_passed(index: int)
signal lap_completed(lap_number: int)
var total_checkpoints := 16
var next_checkpoint := 0
var has_started := false
var current_lap := 0
var last_checkpoint := 0

func setup(count: int) -> void:
	total_checkpoints = count
	next_checkpoint = 0
	has_started = false
	current_lap = 0
	last_checkpoint = 0

func checkpoint_hit(index: int) -> bool:
	if total_checkpoints < 2 or index != next_checkpoint:
		return false
	if index == 0 and not has_started:
		has_started = true
		next_checkpoint = 1
		checkpoint_passed.emit(index)
		return true
	last_checkpoint = index
	next_checkpoint = (index + 1) % total_checkpoints
	checkpoint_passed.emit(index)
	if index == 0:
		current_lap += 1
		lap_completed.emit(current_lap)
	return true
