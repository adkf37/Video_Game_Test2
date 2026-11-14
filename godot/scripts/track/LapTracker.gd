extends Node
## Continuous signed route progress. No narrow checkpoint gates to miss.
signal lap_completed(lap_number: int)
var current_lap := 0
var has_started := false
var last_progress := 0.0
var lap_travel := 0.0
var initialized := false

func reset(progress: float) -> void:
	current_lap = 0
	has_started = false
	lap_travel = 0.0
	rebase(progress)

func rebase(progress: float) -> void:
	last_progress = fposmod(progress, 1.0)
	initialized = true

func sample(progress: float) -> void:
	progress = fposmod(progress, 1.0)
	if not initialized:
		rebase(progress)
		return
	var change := wrapf(progress - last_progress, -0.5, 0.5)
	var crossed := last_progress > 0.8 and progress < 0.2 and change > 0
	last_progress = progress
	# Reject discontinuous relocations, while allowing normal off-trail travel.
	if absf(change) > 0.15:
		return
	if not has_started:
		if crossed:
			has_started = true
			lap_travel = progress
		return
	lap_travel += change
	if crossed and lap_travel >= 0.8:
		current_lap += 1
		lap_travel = progress
		lap_completed.emit(current_lap)

func race_progress() -> float:
	if not has_started:
		return last_progress - 1.0 if last_progress > 0.5 else 0.0
	return current_lap + clampf(lap_travel, 0.0, 1.0)
