Task 03 — Chase Camera Follow + Look-Ahead

Goal: Implement a smooth third-person chase camera that follows the sled and feels good at speed.

Files:

godot/scripts/camera/ChaseCamera.gd

godot/scenes/main/Main.tscn (wire-up camera)

godot/scenes/vehicles/Sled.tscn (camera anchor node)

Implementation notes:

Add a Node3D on the sled called CameraAnchor placed slightly above/behind.

Camera should:

Smoothly follow anchor position (lerp).

Smoothly rotate to align behind sled direction.

Add slight look-ahead based on sled velocity (optional but nice).

Include tunables in script: distance, height, follow_smooth, rotate_smooth, lookahead_amount.

Keep camera stable; avoid sudden snaps.

Acceptance tests:

Driving around keeps the sled centered with comfortable framing.

Camera lags slightly (smooth), but never loses the sled.

Turning doesn’t cause nausea (no rapid oscillations).

Non-goals:

No camera collision avoidance yet.

Done when:

 ChaseCamera.gd attached and working

 CameraAnchor exists on sled

 Tunables are easy to edit