# Course building

`godot/scripts/track/AlpineTrack.gd` generates Alpine Valley, Jungle Rush and Candy Kingdom from separate closed Catmull-Rom control-point layouts sampled at 320 positions. Terrain, start line, nearest recovery poses and minimap use the same spline.

1. Edit the selected course's control points in `_build_path()`.
2. Keep turns broad enough for a 25 m/s sled and neighboring sections well separated.
3. Use gentle elevation changes and broad recoverable shoulders.
4. Trail half-width comes from difficulty: 10 / 8 / 6.8 m.
5. Keep procedural scenery deterministic and outside the racing line.
6. Drive all three laps and run NPC validation at every difficulty after changing layouts.

## Progress and recovery

`LapTracker.gd` samples signed route progress, arming at the first forward crossing of the finish line. Forward travel around the route then earns laps. Reversing subtracts progress; sudden discontinuous jumps are rejected. Recovery rebases the sampler without adding lap travel.

There are no narrow checkpoint gates. Leaving the road imposes a strong speed cap instead of requiring a return to a missed marker. Three completed circuits finish the race.

## Scenery

Snowy art remains in `AlpineTrack.gd`. `BiomeDecor.gd` builds jungle palms, canopy, vines, temple and waterfall, plus candy lollipops, gumdrops, cupcakes and castle. All use shared low-poly helpers in `scripts/art/AlpineArt.gd`. No downloaded art is required.
