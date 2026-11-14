extends Camera3D
var target: Node3D
var manager: Node
var elapsed := 0.0

func _ready() -> void:
	target = get_parent().get_node("PlayerSled")
	manager = get_parent().get_node("RaceManager")
	far = 700
	snap()

func snap() -> void:
	if not target:
		return
	global_position = target.global_position + target.global_basis.z * SledTuning.CAMERA_DISTANCE + Vector3.UP * SledTuning.CAMERA_HEIGHT
	look_at(target.global_position - target.global_basis.z * 3.5 + Vector3.UP)

func _physics_process(delta: float) -> void:
	if not target:
		return
	elapsed += delta
	var menu: bool = manager.state == manager.RaceState.MENU
	var desired := target.global_position + target.global_basis.z * SledTuning.CAMERA_DISTANCE + Vector3.UP * SledTuning.CAMERA_HEIGHT
	var look := target.global_position - target.global_basis.z * 4.0 + Vector3.UP
	if menu:
		desired = target.global_position + target.global_basis * Vector3(12.0 + sin(elapsed * 0.12) * 2.0, 7.0, 11.0)
		look = target.global_position + target.global_basis * Vector3(-4.0, 1.0, -4.0)
	global_position = global_position.lerp(desired, 1.0 - exp(-5.5 * delta))
	var facing := global_transform.looking_at(look, Vector3.UP)
	global_basis = global_basis.slerp(facing.basis, 1.0 - exp(-8.0 * delta)).orthonormalized()
	var target_fov := 66.0 if menu else 70.0 + clampf(target.get_speed_kph() / 130.0, 0, 1) * 9.0
	fov = lerpf(fov, target_fov, 1.0 - exp(-3.0 * delta))
