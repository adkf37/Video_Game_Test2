Task 02 — Player Sled: Basic Arcade Movement on Flat Plane

Goal: Add a controllable sled that accelerates, brakes, and steers on a flat plane.

Files:

godot/scenes/vehicles/Sled.tscn

godot/scripts/vehicle/SledController.gd

godot/scripts/vehicle/SledTuning.gd

docs/controls.md (update)

Implementation notes:

Use a simple setup first:

CharacterBody3D for the sled (simpler) or RigidBody3D (more physics-y). For MVP, prefer CharacterBody3D for stability.

Placeholder visuals:

a MeshInstance3D (box/capsule) + CollisionShape3D.

Input actions (Project Settings → Input Map):

move_forward, move_back, turn_left, turn_right

Implement simple arcade motion:

Maintain speed scalar.

Apply forward velocity along sled’s forward vector.

Rotate sled yaw based on steering input and current speed.

Put all tunables in SledTuning.gd (accel, max_speed, turn_rate, brake, drag).

Acceptance tests:

In Main.tscn, the player spawns and can drive with WASD (or arrows).

Releasing inputs gradually slows the sled.

Steering at zero speed does little; steering at speed turns meaningfully.

No jittering or falling through the ground.

Non-goals:

No drifting, no collisions with walls, no camera yet.

Done when:

 Sled.tscn exists and drives on a plane

 All constants live in SledTuning.gd

 Controls documented in docs/controls.md