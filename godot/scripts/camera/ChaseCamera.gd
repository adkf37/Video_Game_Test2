extends Camera3D
var target: Node3D
var manager: Node
var player_index := 0
var elapsed := 0.0

func _ready() -> void:
	add_to_group("race_cameras")
	manager = get_tree().get_first_node_in_group("race")
	if not target:
		target = manager.get_parent().get_node("PlayerSled")
	far = 700
	near = 0.08
	snap()

func snap() -> void:
	if not target:
		return
	global_position = target.global_position + target.global_basis.z * SledTuning.CAMERA_DISTANCE + Vector3.UP * SledTuning.CAMERA_HEIGHT
	look_at(target.global_position - target.global_basis.z * 3.5 + Vector3.UP)

func _physics_process(delta: float) -> void:
	if not target or not is_current():
		return
	elapsed += delta
	var menu: bool = manager.state == manager.RaceState.MENU
	if not menu and manager.state != manager.RaceState.PAUSED and Input.is_action_just_pressed(target.input_prefix() + "camera"):
		GameState.camera_modes[player_index] = 1 - GameState.camera_modes[player_index]
	var pov: bool = GameState.camera_modes[player_index] == 1 and not menu
	# Hide only this musher in this camera. Other players still see the full model.
	set_cull_mask_value(player_index + 2, not pov)
	var desired := target.global_position + target.global_basis.z * SledTuning.CAMERA_DISTANCE + Vector3.UP * SledTuning.CAMERA_HEIGHT
	var look := target.global_position - target.global_basis.z * 4.0 + Vector3.UP
	if menu:
		desired = target.global_position + target.global_basis * Vector3(12.0 + sin(elapsed * 0.12) * 2.0, 7.0, 11.0)
		look = target.global_position + target.global_basis * Vector3(-4.0, 1.0, -4.0)
	elif pov:
		desired = target.visual.to_global(target.visual.musher_eye())
		# Follow the slope with the dogs, with a stable horizon and no camera roll.
		look = desired - target.visual.global_basis.z * 18.0 - Vector3.UP * 1.3
	global_position = desired if pov else global_position.lerp(desired, 1.0 - exp(-5.5 * delta))
	var facing := global_transform.looking_at(look, Vector3.UP)
	global_basis = global_basis.slerp(facing.basis, 1.0 - exp(-(14.0 if pov else 8.0) * delta)).orthonormalized()
	var target_fov := 66.0 if menu else (82.0 if pov else 70.0) + clampf(target.get_speed_kph() / 130.0, 0, 1) * 6.0
	fov = lerpf(fov, target_fov, 1.0 - exp(-3.0 * delta))
