extends Control
var track: AlpineTrack
var sled: Node3D
var manager: Node
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	queue_redraw()

func _map(point: Vector3) -> Vector2:
	return Vector2(point.x, point.z) * 0.84 + size * 0.5

func _draw() -> void:
	if not track or track.points.is_empty():
		return
	draw_style_box(_background(), Rect2(Vector2.ZERO, size))
	var line := PackedVector2Array()
	for point in track.points:
		line.append(_map(point))
	line.append(line[0])
	draw_polyline(line, Color("#557b87"), 9, true)
	draw_polyline(line, Color("#cee4e9"), 3, true)
	var expected := float(manager.lap_tracker.next_checkpoint) / track.CHECKPOINT_COUNT
	draw_circle(_map(track.frame_at(expected).origin), 4, Color("#f1ce7b"))
	draw_circle(_map(track.points[0]), 4, Color("#f8f1df"))
	for rival in manager.rivals:
		draw_circle(_map(rival.global_position), 4.5, rival.team_color)
	var p := _map(sled.global_position)
	var facing := -sled.global_basis.z
	var f := Vector2(facing.x, facing.z)
	draw_colored_polygon(PackedVector2Array([p + f * 8, p + f.rotated(2.5) * 6, p + f.rotated(-2.5) * 6]), Color("#ff977a"))

func _background() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.15, 0.19, 0.88)
	style.set_corner_radius_all(12)
	return style
