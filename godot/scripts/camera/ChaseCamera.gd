extends Camera3D
## Smooth third-person chase camera.
## Follows a target node (the sled) with lerp-based smoothing
## and optional velocity look-ahead.

# ── Tunables ─────────────────────────────────────────────
@export var distance : float = 8.0    ## How far behind the target
@export var height   : float = 4.0    ## How far above the target
@export var follow_smooth  : float = 5.0   ## Position lerp speed
@export var rotate_smooth  : float = 4.0   ## Rotation lerp speed
@export var lookahead_amount : float = 2.0  ## Look-ahead based on velocity

# ── References ───────────────────────────────────────────
@export var target_path: NodePath = ""
var target: Node3D = null

func _ready() -> void:
	set_as_top_level(true)  # Detach from parent so we can smooth-follow independently
	# Auto-find sled if no target_path set
	if target_path != NodePath(""):
		target = get_node(target_path)
	else:
		# Search for the PlayerSled in the scene tree
		await get_tree().process_frame
		var sled = get_tree().root.find_child("PlayerSled", true, false)
		if sled:
			target = sled
	if target:
		_snap_to_target()
		print("[ChaseCamera] Following: ", target.name)
	else:
		push_warning("[ChaseCamera] No target found!")

func _snap_to_target() -> void:
	# Snap to initial position immediately (no lerp on first frame)
	if target:
		var target_pos = target.global_position
		var back = target.global_basis.z.normalized()
		global_position = target_pos + back * distance + Vector3.UP * height
		look_at(target_pos + Vector3.UP * 1.0, Vector3.UP)

func _physics_process(delta: float) -> void:
	if not target:
		return

	var target_pos = target.global_position

	# ── Desired camera position: behind + above target ───
	var back_dir = target.global_basis.z.normalized()  # sled's +Z is backward
	var desired_pos = target_pos + back_dir * distance + Vector3.UP * height

	# ── Velocity look-ahead ──────────────────────────────
	if target is CharacterBody3D:
		var vel = target.velocity
		var horizontal_vel = Vector3(vel.x, 0, vel.z)
		desired_pos += horizontal_vel.normalized() * lookahead_amount * clampf(horizontal_vel.length() / 20.0, 0.0, 1.0)

	# ── Smooth follow position ───────────────────────────
	global_position = global_position.lerp(desired_pos, follow_smooth * delta)

	# ── Smooth look-at ───────────────────────────────────
	var look_target = target_pos + Vector3.UP * 1.0
	var desired_transform = global_transform.looking_at(look_target, Vector3.UP)
	global_transform = global_transform.interpolate_with(desired_transform, rotate_smooth * delta)
