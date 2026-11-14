> Historical design proposal. For the playable November 2026 rebuild, see README.md and IMPLEMENTATION_SUMMARY.md. Feature claims below do not describe the current shipped milestone.

# Dog Sled Visual Assets Guide

## Overview
The game features **cartoon dogs pulling sleds** as the racing vehicles. This creates a whimsical, family-friendly aesthetic that sets the game apart from typical racing games.

## Visual Design Concept

### Sled Team Composition
- **Lead Dog**: 1 dog at front (largest, most detailed)
- **Team Dogs**: 2-4 dogs in middle pairs
- **Sled**: Behind the dog team with visible harness connections
- **Rider** (optional): Small character on sled

### Art Style
- **Cartoon proportions**: Big heads, expressive eyes, simplified bodies
- **Friendly appearance**: Happy, energetic dogs (Huskies, Malamutes, mixed breeds)
- **Vibrant colors**: Each dog can have unique fur patterns and colors
- **Dynamic animation**: Dogs should appear to run (cycle animation)

## Asset Structure

Place custom art assets in:
```
godot/assets/vehicles/dog_sled/
├── models/
│   ├── dog_lead.glb         — Lead dog model
│   ├── dog_team.glb         — Team dog model (reusable)
│   ├── sled_base.glb        — Sled chassis
│   ├── harness.glb          — Harness connecting dogs to sled
│   └── rider.glb (optional) — Musher character
├── textures/
│   ├── dog_fur_01.png       — Husky pattern
│   ├── dog_fur_02.png       — Brown/white mix
│   ├── dog_fur_03.png       — Black/white
│   ├── sled_wood.png        — Wooden sled texture
│   └── harness_leather.png  — Harness material
└── animations/
    ├── dog_run.anim         — Running cycle
    ├── dog_turn_left.anim   — Lean left animation
    ├── dog_turn_right.anim  — Lean right animation
    └── dog_idle.anim        — Breathing/waiting animation
```

## Placeholder Setup (Current)

Until custom art is created, use these primitives in `Sled.tscn`:

```
Sled (CharacterBody3D + SledController.gd)
├── DogTeam (Node3D)
│   ├── LeadDog (MeshInstance3D)
│   │   ├── Mesh: CapsuleMesh (0.3 radius, 0.8 length)
│   │   ├── Material: Orange/Brown tint
│   │   └── Eyes: Two small sphere meshes (black)
│   ├── TeamDog_L (MeshInstance3D)
│   │   └── Mesh: CapsuleMesh, slightly smaller
│   ├── TeamDog_R (MeshInstance3D)
│   │   └── Mesh: CapsuleMesh, slightly smaller
│   └── Harness (Node3D)
│       └── Visual lines connecting dogs to sled (thin cylinders)
├── SledBody (MeshInstance3D)
│   ├── Mesh: BoxMesh (1.5 length × 0.8 width × 0.3 height)
│   └── Material: Wood texture or brown
└── CollisionShape3D
    └── Shape: BoxShape3D matching sled dimensions
```

## Animation System

### Current: No Animation
The placeholder simply moves forward. Dogs don't animate yet.

### Planned: AnimationPlayer
Once custom models are imported:
1. Add `AnimationPlayer` node to `Sled`
2. Import animations from `.glb` files
3. Script triggers:
   - `dog_run`: Plays continuously when moving
   - `dog_turn_left/right`: Blends in when steering
   - `dog_idle`: When speed = 0

### Animation Speed Sync
Scale animation playback speed based on sled velocity:
```gdscript
animation_player.speed_scale = current_speed / MAX_SPEED
```

## Customization System (Future Feature)

Allow players to customize their dog team:
- **Breed selection**: Different dog appearances (Husky, Malamute, mixed)
- **Fur colors**: Preset color patterns or custom colors
- **Accessories**: Bandanas, goggles, decorative harness
- **Sled styles**: Wooden, modern, fantasy designs

This customization can be saved per player profile.

## Tips for Character Artists

### Model Requirements
- **Polycount**: Keep dogs under 2,000 triangles each for performance
- **Rigging**: Simple rig with spine, legs, head, tail
- **Texture resolution**: 512×512 per dog, 1024×1024 for sled
- **File format**: Export as `.glb` (Godot-friendly)

### Animation Requirements
- **Framerate**: 30 FPS is sufficient for cartoon style
- **Loop**: Ensure run cycle loops seamlessly
- **Blend**: Turn animations should be additive or layered

### Style Reference
Think: **Disney's "Balto"**, **"101 Dalmatians"**, **"Paw Patrol"** — cartoony but appealing.

## Implementation Checklist

- [ ] Create or commission dog character models
- [ ] Create sled base model
- [ ] Design harness connectors
- [ ] Create 3-5 fur texture variants
- [ ] Animate dog run cycle
- [ ] Animate turn/lean behaviors
- [ ] Import models into Godot `assets/vehicles/dog_sled/models/`
- [ ] Update `Sled.tscn` to replace placeholders with actual models
- [ ] Test animations with SledController movement
- [ ] Add customization UI (optional)

## Testing

When testing with placeholder geometry:
1. Ensure collision matches visual sled dimensions
2. Check that "dogs" are visible ahead of sled
3. Verify harness connections look reasonable
4. Test camera framing shows the dog team clearly

When final models are imported:
1. Verify animations play correctly
2. Check performance (FPS should remain stable)
3. Test that models don't clip through terrain
4. Ensure dogs remain visible during turns
