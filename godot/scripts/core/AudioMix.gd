class_name AudioMix
## Every audio level, curve and pitch range in one place. Edit a value, then run the game; nothing else needs touching.
## Levels are in dB (0 is full scale, -6 is half the amplitude, -80 is silent). The player's -/+ volume sits on top of all of this.

# --- Quick A/B testing --------------------------------------------------------
# Put group names here to silence them, e.g. ["ambience", "foley", "rivals"]. Leave empty for the full mix.
# Groups: music, drums, ambience, foley (your sled and dogs panting), rivals, dogs, sfx, ui.
const MUTED_GROUPS: Array[String] = []
const SILENT := -80.0

# --- Master bus processing ----------------------------------------------------
# Gentle high-frequency cut to tame hiss. Set HIGH_SHELF_DB to 0 to bypass it.
const HIGH_SHELF_HZ := 6500.0
const HIGH_SHELF_DB := -3.0
# Hard low-pass. 0 disables it; try 9000 to 12000 for a softer, less fizzy mix.
const LOW_PASS_HZ := 0.0
const LIMITER_CEILING_DB := -1.0
const LIMITER_THRESHOLD_DB := 0.0

# --- Music ---------------------------------------------------------------------
const MUSIC_RACING_DB := -19.0
const MUSIC_MENU_DB := -24.0
const MUSIC_DUCK_DB := -4.0 # extra cut while an effect plays
const MUSIC_PAUSED_DB := -8.0
const MUSIC_FINAL_LAP_DB := 1.5
const MUSIC_FADE_DB_PER_SEC := 45.0
# The drum layer fades between these levels as intensity rises from 0 to 1.
const DRUMS_QUIET_DB := -26.0
const DRUMS_FULL_DB := 0.0
# Intensity targets: menus, countdown, racing (base plus a speed bonus) and the final lap.
const INTENSITY_MENU := 0.2
const INTENSITY_COUNTDOWN := 0.45
const INTENSITY_RACING := 0.7
const INTENSITY_SPEED_BONUS := 0.3
const INTENSITY_FINAL_LAP := 1.0
const INTENSITY_PER_SEC := 0.35

# --- Ambience bed ----------------------------------------------------------------
const AMBIENCE_RACING_DB := -30.0
const AMBIENCE_MENU_DB := -34.0
const AMBIENCE_PAUSED_DB := -8.0
const AMBIENCE_FADE_DB_PER_SEC := 30.0

# --- Your sled and team (loops follow speed from QUIET at a standstill to LOUD at top speed) ---
const GLIDE_QUIET_DB := -52.0
const GLIDE_LOUD_DB := -28.0
const GLIDE_OFFROAD_CUT_DB := 6.0
const SCRAPE_QUIET_DB := -38.0 # drifting only
const SCRAPE_LOUD_DB := -28.0
const ROUGH_QUIET_DB := -40.0 # off the trail only
const ROUGH_LOUD_DB := -30.0
const PANT_BASE_DB := -30.0
const PANT_SPEED_RANGE_DB := 6.0
const PANT_TEAM_SIZE_DB := 0.5 # multiplies the dB difference of the team size against 4 dogs
const FOLEY_FADE_DB_PER_SEC := 60.0
# Pitch is base + range * speed (0 to 1).
const GLIDE_PITCH := Vector2(0.8, 0.55)
const SCRAPE_PITCH := Vector2(0.85, 0.3)
const ROUGH_PITCH := Vector2(0.9, 0.3)
const PANT_PITCH := Vector2(0.9, 0.25)

# --- Rivals (positional) -------------------------------------------------------
const RIVAL_GLIDE_QUIET_DB := -54.0
const RIVAL_GLIDE_LOUD_DB := -32.0
const RIVAL_PITCH := Vector2(0.8, 0.55)
const RIVAL_UNIT_SIZE := 6.0
const RIVAL_MAX_DISTANCE := 70.0
const SPATIAL_SFX_DB := -6.0
const SPATIAL_UNIT_SIZE := 8.0
const SPATIAL_MAX_DISTANCE := 80.0
const DOPPLER_LIMITS := Vector2(0.85, 1.15)

# --- Event sounds --------------------------------------------------------------
const EVENT_DEFAULT_DB := -9.0
const EVENT_DB := {"crash": -5.0, "coconut": -5.0, "pickup": -5.0, "boost": -5.0, "finish": -5.0}
const PLAYER_TWO_PITCH := 1.03
# Variation applied to every play of the sounds that have variants.
const VARIANT_PITCH_SPREAD := 1.05
const VARIANT_VOLUME_SPREAD_DB := 1.5

# --- Dogs -----------------------------------------------------------------------
const BREED_PITCH := [1.0, 1.22, 0.72, 1.55] # Huskies, Corgis, Mastiffs, Chihuahuas
const DOG_CHORUS_DB := -9.0
const DOG_CHORUS_STEP_DB := -2.0 # each extra dog in the chorus
const DOG_HOWL_DB := -8.0
const DOG_YIP_DB := -13.0
const DOG_BARK_DB := -12.0
const DOG_YELP_DB := -11.0
const DOG_BARK_SPREAD := Vector2(1.08, 1.5) # random pitch, random volume offset in dB

# --- Menus -----------------------------------------------------------------------
const UI_DB := -7.0
const UI_HOVER_DB := -14.0

static func muted(group: String) -> bool:
	return group in MUTED_GROUPS

# The level to apply to a player in a group, honoring MUTED_GROUPS.
static func level(group: String, db: float) -> float:
	return SILENT if group in MUTED_GROUPS else db

static func event_db(kind: String) -> float:
	return EVENT_DB.get(kind, EVENT_DEFAULT_DB)

static func configure_master(bus: int) -> void:
	if HIGH_SHELF_DB != 0.0:
		var shelf := AudioEffectHighShelfFilter.new()
		shelf.cutoff_hz = HIGH_SHELF_HZ
		shelf.gain = db_to_linear(HIGH_SHELF_DB)
		AudioServer.add_bus_effect(bus, shelf)
	if LOW_PASS_HZ > 0.0:
		var low_pass := AudioEffectLowPassFilter.new()
		low_pass.cutoff_hz = LOW_PASS_HZ
		AudioServer.add_bus_effect(bus, low_pass)
	var limiter := AudioEffectLimiter.new()
	limiter.ceiling_db = LIMITER_CEILING_DB
	limiter.threshold_db = LIMITER_THRESHOLD_DB
	AudioServer.add_bus_effect(bus, limiter)
