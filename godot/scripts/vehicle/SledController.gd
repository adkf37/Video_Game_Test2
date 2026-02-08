extends CharacterBody3D
## Player Sled Controller — arcade-style movement.
## Reads input, accelerates/brakes, steers, applies gravity.
## All tuning constants come from SledTuning.gd.

const GRAVITY : float = 9.8

var current_speed : float = 0.0

func _physics_process(delta: float) -> void:
	# ── Input ────────────────────────────────────────────
	var accel_input := (
		Input.get_action_strength("move_forward")
		- Input.get_action_strength("move_back")
	)
	var steer_input := (
		Input.get_action_strength("turn_right")
		- Input.get_action_strength("turn_left")
	)

	# ── Acceleration / Braking ───────────────────────────
	if accel_input > 0.0:
		current_speed += SledTuning.ACCELERATION * accel_input * delta
	elif accel_input < 0.0:
		current_speed += SledTuning.BRAKE_FORCE * accel_input * delta
	else:
		# Coast — apply drag toward zero
		current_speed = move_toward(current_speed, 0.0, SledTuning.DRAG * delta)

	current_speed = clampf(
		current_speed,
		-SledTuning.MAX_SPEED * 0.3,  # limited reverse
		SledTuning.MAX_SPEED
	)

	# ── Steering ─────────────────────────────────────────
	if absf(current_speed) > SledTuning.MIN_SPEED_TO_TURN:
		var speed_ratio := clampf(
			absf(current_speed) / SledTuning.MAX_SPEED, 0.3, 1.0
		)
		var turn := steer_input * SledTuning.TURN_RATE * speed_ratio * delta
		rotate_y(-turn)

	# ── Gravity ──────────────────────────────────────────
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	# ── Apply velocity along sled forward (-Z) ──────────
	var forward := -transform.basis.z
	velocity.x = forward.x * current_speed
	velocity.z = forward.z * current_speed

	move_and_slide()

## Returns current speed in display units (km/h-ish).
func get_speed_kph() -> float:
	return absf(current_speed) * 3.6
