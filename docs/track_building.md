# Dogsled Kart — Track Building Guide

## Overview
Tracks are built as separate `.tscn` scene files in `godot/scenes/tracks/`.
`Main.tscn` instances the active track scene.

## Track_Alpine01 Structure

The first track is a simple oval loop made from primitive shapes:

```
Track_Alpine01 (Node3D)
├── Ground (StaticBody3D)          — large snow plane
├── Road (Node3D)                  — visual road surface strips
│   ├── Straight_01..04            — long box meshes (dark grey)
│   └── Corner_01..04              — positioned box meshes at turns
├── Walls (Node3D)                 — invisible + visible boundary walls
│   ├── OuterWall_01..N            — StaticBody3D boxes around outside
│   └── InnerWall_01..N            — StaticBody3D boxes on inside edge
├── Landmarks (Node3D)             — navigation helpers
│   └── Tree_01..N                 — cylinder + sphere "trees"
└── StartFinish (Node3D)           — marks lap start position
```

## How to Edit the Track

### Moving walls / road segments
1. Open `Track_Alpine01.tscn` in Godot
2. Select any wall or road segment
3. Use the Move tool (W) to reposition
4. Test by pressing F5 — drive around and check collisions

### Adding new road segments
1. Add a `MeshInstance3D` child under the `Road` node
2. Set mesh to a `BoxMesh` sized appropriately (e.g., 12×0.05×60 for a straight)
3. Apply the road material (dark grey)

### Adding walls
1. Add a `StaticBody3D` child under `Walls` with a `CollisionShape3D` + `BoxShape3D`
2. Optionally add a `MeshInstance3D` to make it visible
3. Position along the track edge

### Track dimensions
- Overall footprint: ~200m × 140m
- Road width: ~12m (forgiving)
- Walls: ~2m tall, just enough to block the sled

## Checkpoints
Checkpoints are added in Task 05. They go inside the track scene under a `Checkpoints` node.
