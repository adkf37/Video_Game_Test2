class_name SledTuning
## Centralised tuning constants for the player sled.
## ALL vehicle numbers live here — never scatter them in other scripts.

# ── Movement ─────────────────────────────────────────────
const ACCELERATION : float = 20.0   ## Forward push per second
const MAX_SPEED    : float = 30.0   ## Top speed (m/s)
const BRAKE_FORCE  : float = 25.0   ## Deceleration when braking
const DRAG         : float = 5.0    ## Passive speed loss per second (coast)
const TURN_RATE    : float = 2.5    ## Radians/sec at full speed
const MIN_SPEED_TO_TURN : float = 1.5  ## Below this, steering is ignored

# ── Future (Phase 2+) ───────────────────────────────────
const BOOST_STRENGTH   : float = 40.0
const BOOST_DURATION   : float = 1.5
const WALL_BOUNCE      : float = 0.3
const OFFROAD_SLOWDOWN : float = 0.6
