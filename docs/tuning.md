# Dogsled Kart — Tuning Reference

All vehicle tuning constants live in `godot/scripts/vehicle/SledTuning.gd`.
**Never scatter tuning numbers in other scripts** — always reference `SledTuning.*`.

## Current Values

| Constant           | Value | Unit      | Notes                          |
|--------------------|-------|-----------|--------------------------------|
| ACCELERATION       | 20.0  | m/s²      | Forward push per second        |
| MAX_SPEED          | 30.0  | m/s       | ~108 km/h display              |
| BRAKE_FORCE        | 25.0  | m/s²      | Deceleration when braking      |
| DRAG               | 5.0   | m/s²      | Passive coast deceleration     |
| TURN_RATE          | 2.5   | rad/s     | At full speed                  |
| MIN_SPEED_TO_TURN  | 1.5   | m/s       | Below this, steering ignored   |
| BOOST_STRENGTH     | 40.0  | m/s²      | Phase 2+                       |
| BOOST_DURATION     | 1.5   | s         | Phase 2+                       |
| WALL_BOUNCE        | 0.3   | ratio     | Phase 2+                       |
| OFFROAD_SLOWDOWN   | 0.6   | ratio     | Phase 2+                       |

## How to Tune
1. Open `SledTuning.gd`.
2. Change the constant value.
3. Run the game — changes take effect immediately (no reload needed for constants).
4. Update this doc when committing tuning changes.
