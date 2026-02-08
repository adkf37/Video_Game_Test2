Task 04 — Track Alpine01: Simple Loop + Boundaries

Goal: Create a first drivable track scene with a loop, ground, and basic boundaries so the player can do laps later.

Files:

godot/scenes/tracks/Track_Alpine01.tscn

godot/scenes/main/Main.tscn (load track)

docs/track_building.md (create if missing)

Implementation notes:

Keep this super simple:

Flat plane ground with a loop “road” area (different color material).

Boundary walls made from box meshes + collisions OR invisible collider barriers.

Use modular pieces (straight + curve segments) or “blockout” using primitives.

Add a few “landmarks” props (trees as cylinders) to help navigation.

Place a StartFinish marker (empty Node3D) where lap start will be.

Acceptance tests:

Player sled spawns on track and can drive a full loop without falling off.

Colliding with boundaries prevents leaving play area (even if it’s a simple wall).

Non-goals:

No lap counting yet, no checkpoints yet, no offroad slowdown.

Done when:

 Track scene exists and is instanced by Main.tscn

 Boundaries block the player from escaping

 docs/track_building.md explains how to edit the track