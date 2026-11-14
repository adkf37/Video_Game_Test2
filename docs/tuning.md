# Sled tuning

All movement constants live in `godot/scripts/vehicle/SledTuning.gd`.

| Setting | Value | Purpose |
|---|---:|---|
| ACCELERATION | 12 m/s? | Responsive launch without instant top speed |
| MAX_SPEED | 25 m/s | 90 km/h normal cap |
| REVERSE_SPEED | 6 m/s | Controlled recovery in reverse |
| BRAKE_FORCE | 24 m/s? | Braking response |
| DRAG | 3 m/s? | Coasting |
| TURN_RATE | 1.25 rad/s | Full steering response |
| STEER_RESPONSE | 6 /s | Keyboard steering smoothing |
| GRIP | 7 /s | Normal momentum alignment |
| DRIFT_GRIP | 1.8 /s | Sideways momentum while drifting |
| DRIFT_TURN | 1.3 | Turn multiplier during drift |
| OFFROAD_SPEED | 13 m/s | Deep-snow speed limit |
| BOOST_SPEED | 36 m/s | 129.6 km/h boost cap |
| BOOST_ACCEL | 22 m/s? | Boost acceleration |
| BOOST_DRAIN | 38 /s | Approximately 2.6 seconds from full |
| BOOST_RECHARGE | 13 /s | Recharge while not boosting |
| GRAVITY | 22 m/s? | Hill contact and landings |
| RECOVERY_PENALTY | 3 s | Added to current lap and race |
| CAMERA_DISTANCE | 10.5 m | Chase distance |
| CAMERA_HEIGHT | 5.5 m | Chase height |

Speed display uses measured physical velocity, not requested speed. Steering reverses naturally when backing up. Drift changes grip rather than simply raising speed. Camera interpolation uses exponential smoothing.

When changing handling, run both the smoke suite and the three-lap driving test, then play manually. The bot validates traversability; it does not establish whether controls feel fun.

## NPC teams

Rivals inherit `SledController.gd`; they supply throttle, steering and boost inputs instead of reading the keyboard. `RivalController.gd` looks 10 m ahead for steering and 24 m ahead for corner braking. Boosts last 0.8 seconds and are allowed on straight sections, with 12-14 second intervals.

`RaceManager.gd` creates Juniper, Kodiak and Mika with throttle targets of 0.82, 0.88 and 0.94 and lanes at -3.1, 0 and 3.1 m. Passing offsets stay within 3.8 m of the center. There is no rubber-banding. Run `tests/npc_race.gd` after changing these values; it validates both autonomous completion and a winnable player race.
