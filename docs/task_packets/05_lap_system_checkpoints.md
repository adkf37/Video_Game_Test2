Task 05 — Lap System: Checkpoints + LapTracker + RaceManager (Minimal)

Goal: Implement ordered checkpoints and lap counting (time trial).

Files:

godot/scenes/props/Checkpoint.tscn

godot/scripts/track/Checkpoint.gd

godot/scripts/track/LapTracker.gd

godot/scripts/core/RaceManager.gd

godot/scenes/main/Main.tscn (wire RaceManager)

godot/scenes/tracks/Track_Alpine01.tscn (place checkpoints)

Implementation notes:

Checkpoint.tscn:

Area3D + CollisionShape3D trigger volume

exported checkpoint_index:int

LapTracker:

tracks current expected checkpoint index

increments when correct checkpoint is hit

lap increments when last checkpoint hit then Start/Finish crossed

RaceManager:

holds lap_count target (default 3)

tracks timer start/stop

Place 8 checkpoints around the track (after corners and mid-straights).

Acceptance tests:

Starting the scene begins a timer.

Driving through checkpoints out of order does NOT advance progress.

Completing a full loop increments lap number.

After 3 laps, race ends (state flips to “Results”).

Non-goals:

No AI, no items, no fancy countdown yet (optional later).

Done when:

 Ordered checkpoint logic works reliably

 Lap count completes and triggers finish state

 RaceManager can restart the race (simple reload)