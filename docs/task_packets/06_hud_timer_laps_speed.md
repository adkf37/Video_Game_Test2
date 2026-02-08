Task 06 — HUD: Timer + Laps + Speed Readout

Goal: Add a minimal HUD showing timer, lap, and speed; show a simple results screen at finish.

Files:

godot/scenes/ui/HUD.tscn

godot/scripts/ui/HUD.gd

godot/scenes/main/Main.tscn (instance HUD)

godot/scripts/core/RaceManager.gd (expose signals/state)

Implementation notes:

HUD elements:

TimerLabel

LapLabel

SpeedLabel

FinishPanel (hidden until race end)

RaceManager should expose:

current time (float seconds)

current lap / max laps

race state (racing/finished)

signal race_finished(final_time)

Speed can be computed from sled velocity magnitude (m/s) and displayed as “km/h” or arbitrary units.

Acceptance tests:

HUD appears in-race and updates live.

Timer starts at race start and stops at finish.

Lap display matches LapTracker.

On finish, show final time and a “Restart” button that restarts the scene.

Non-goals:

No polished UI, no minimap, no position tracking.

Done when:

 HUD updates every frame without errors

 Finish panel shows and restart works

 RaceManager is the single source of truth for race timing/state