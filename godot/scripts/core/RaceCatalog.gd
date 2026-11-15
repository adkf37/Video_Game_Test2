class_name RaceCatalog
extends RefCounted
const COURSES := ["Alpine Valley", "Jungle Rush", "Candy Kingdom", "City Sprint"]
const DIFFICULTIES := ["Easy", "Medium", "Hard"]
const MODES := ["Solo + 3 rivals", "2 players + 2 rivals"]
const BREEDS := ["Huskies", "Corgis", "Mastiffs", "Chihuahuas"]
const TEAM_COUNTS := [4, 8, 2, 12]
const SLEDS := ["Standard wood", "Carbon racer", "Chocolate", "King's throne"]
const WIDTHS := [10.0, 8.0, 6.8]
const FIRST_CUT_WIDTH := 6.0
const SECOND_CUT_WIDTH := 8.0
const FIRST_CUT_CAPS := [20.0, 18.0, 16.0]
const OFFROAD_CAPS := [10.0, 8.0, 6.5]
const NPC_PACE := [0.76, 0.86, 0.95]
const CHALLENGE_MULTIPLIER := 1.25
const NPC_ATTACK_INTERVAL := [11.0, 7.0, 4.5]

static func offroad_limit(distance: float, half_width: float, difficulty: int) -> float:
	var depth := maxf(0, distance - half_width)
	if depth <= FIRST_CUT_WIDTH:
		return lerpf(25.0, FIRST_CUT_CAPS[difficulty], smoothstep(0, FIRST_CUT_WIDTH, depth))
	return lerpf(FIRST_CUT_CAPS[difficulty], OFFROAD_CAPS[difficulty],
		smoothstep(0, SECOND_CUT_WIDTH, depth - FIRST_CUT_WIDTH))
