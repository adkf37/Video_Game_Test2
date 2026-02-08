extends Control
## Overhead minimap — draws the track outline and sled position.
## Purely 2D drawing mapped from world XZ coordinates.

# ── Track extents (match Track_Alpine01 layout) ─────────
const TRACK_MIN_X := -80.0
const TRACK_MAX_X := 80.0
const TRACK_MIN_Z := -65.0
const TRACK_MAX_Z := 65.0
const TRACK_PADDING := 10.0

# ── Road segments (world XZ coords, as line chains) ─────
# Outer boundary: N/S ±62, E/W ±76, diagonal corners
# Inner island:   N/S ±30, E/W ±40, diagonal corners
var road_outer: Array[Vector2] = [
	Vector2(60, 62), Vector2(-60, 62),    # South outer
	Vector2(-63, 52),                      # SW corner
	Vector2(-76, 45), Vector2(-76, -45),  # West outer
	Vector2(-63, -52),                     # NW corner
	Vector2(-60, -62), Vector2(60, -62),  # North outer
	Vector2(63, -52),                      # NE corner
	Vector2(76, -45), Vector2(76, 45),    # East outer
	Vector2(63, 52),                       # SE corner
	Vector2(60, 62),                       # Close loop
]
var road_inner: Array[Vector2] = [
	Vector2(27, 30), Vector2(-27, 30),    # South inner
	Vector2(-33, 23),                      # SW corner
	Vector2(-40, 17), Vector2(-40, -17),  # West inner
	Vector2(-33, -23),                     # NW corner
	Vector2(-27, -30), Vector2(27, -30),  # North inner
	Vector2(33, -23),                      # NE corner
	Vector2(40, -17), Vector2(40, 17),    # East inner
	Vector2(33, 23),                       # SE corner
	Vector2(27, 30),                       # Close loop
]

# ── Checkpoint world positions ───────────────────────────
var checkpoint_positions: Array[Vector2] = [
	Vector2(10, 45),   # CP0 — S straight right
	Vector2(-20, 45),  # CP1 — S straight left
	Vector2(-57, 10),  # CP2 — W straight south
	Vector2(-57, -10), # CP3 — W straight north
	Vector2(-10, -45), # CP4 — N straight left
	Vector2(20, -45),  # CP5 — N straight right
	Vector2(57, -10),  # CP6 — E straight north
	Vector2(57, 10),   # CP7 — E straight south
]

var player_sled: Node3D = null
var race_manager: Node = null

func _ready() -> void:
	await get_tree().process_frame
	player_sled = get_tree().root.find_child("PlayerSled", true, false)
	race_manager = get_tree().root.find_child("RaceManager", true, false)

func _process(_delta: float) -> void:
	queue_redraw()

func _world_to_map(world_xz: Vector2) -> Vector2:
	## Convert world XZ to minimap pixel coordinates.
	var map_size = size
	var world_w = (TRACK_MAX_X - TRACK_MIN_X) + TRACK_PADDING * 2
	var world_h = (TRACK_MAX_Z - TRACK_MIN_Z) + TRACK_PADDING * 2
	var scale_val = minf(map_size.x / world_w, map_size.y / world_h)
	var cx = map_size.x * 0.5
	var cy = map_size.y * 0.5
	var px = cx + (world_xz.x - (TRACK_MIN_X + TRACK_MAX_X) * 0.5) * scale_val
	var py = cy + (world_xz.y - (TRACK_MIN_Z + TRACK_MAX_Z) * 0.5) * scale_val
	return Vector2(px, py)

func _draw() -> void:
	# Background
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.08, 0.15, 0.85))
	# Border
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.4, 0.5, 0.6, 1.0), false, 2.0)

	# Draw road (fill between outer and inner as lines)
	_draw_polyline(road_outer, Color(0.5, 0.5, 0.55, 0.6), 3.0)
	_draw_polyline(road_inner, Color(0.5, 0.5, 0.55, 0.6), 3.0)

	# Road surface — draw thick lines along the center path
	var road_center: Array[Vector2] = []
	for i in range(road_outer.size()):
		var outer_pt = road_outer[i]
		var inner_pt = road_inner[i]
		road_center.append((outer_pt + inner_pt) * 0.5)
	_draw_polyline(road_center, Color(0.35, 0.35, 0.4, 0.8), 8.0)

	# Draw checkpoints
	var next_cp := 0
	if race_manager and race_manager.lap_tracker:
		next_cp = race_manager.lap_tracker.next_checkpoint
	for i in range(checkpoint_positions.size()):
		var map_pos = _world_to_map(checkpoint_positions[i])
		if i == next_cp:
			# Next checkpoint — bright pulsing
			draw_circle(map_pos, 6.0, Color(0.2, 1.0, 0.4, 1.0))
		elif i < next_cp:
			# Already passed — dim
			draw_circle(map_pos, 4.0, Color(0.3, 0.6, 0.3, 0.5))
		else:
			# Not yet reached — blue
			draw_circle(map_pos, 4.0, Color(0.3, 0.6, 1.0, 0.7))

	# Start/finish line
	var start_pos = _world_to_map(Vector2(20, 45))
	draw_circle(start_pos, 5.0, Color(0.1, 0.9, 0.2, 0.9))

	# Draw sled position
	if player_sled:
		var sled_xz = Vector2(player_sled.global_position.x, player_sled.global_position.z)
		var sled_map = _world_to_map(sled_xz)
		# Directional arrow
		var fwd = -player_sled.global_basis.z
		var fwd_2d = Vector2(fwd.x, fwd.z).normalized()
		var arrow_len = 10.0
		var arrow_tip = sled_map + fwd_2d * arrow_len
		var arrow_left = sled_map + fwd_2d.rotated(2.5) * arrow_len * 0.6
		var arrow_right = sled_map + fwd_2d.rotated(-2.5) * arrow_len * 0.6
		# Red triangle for sled
		draw_colored_polygon(PackedVector2Array([arrow_tip, arrow_left, arrow_right]), Color(1, 0.2, 0.15, 1.0))
		# White center dot
		draw_circle(sled_map, 3.0, Color(1, 1, 1, 1))

func _draw_polyline(points: Array[Vector2], color: Color, width: float) -> void:
	if points.size() < 2:
		return
	var mapped: PackedVector2Array = PackedVector2Array()
	for pt in points:
		mapped.append(_world_to_map(pt))
	draw_polyline(mapped, color, width, true)
