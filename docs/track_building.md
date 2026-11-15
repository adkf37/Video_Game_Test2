# Course building

`godot/scripts/track/AlpineTrack.gd` generates Alpine Valley, Jungle Rush, Candy Kingdom and City Sprint from separate closed Catmull-Rom layouts sampled at 320 positions. Terrain, start line, recovery poses and minimap use the same spline.

1. Edit the selected course's control points in `_build_path()`.
2. Keep turns broad enough for a 25 m/s sled and neighboring sections well separated.
3. The elevation pass multiplies anchor heights by 1.85 and adds broad rolling climbs. Keep the start/finish apron gentle.
4. Trail half-width follows difficulty: 10 / 8 / 6.8 m. The first cut extends 6 m beyond that and the second cut another 8 m.
5. Keep scenery deterministic and clear of the racing line. Use `ground_height()` to place props on the sloping shoulders.
6. Run solo driving, two-player driving and all NPC difficulty checks after layout changes.

## Progress and recovery

`LapTracker.gd` samples signed route progress, arming at the first forward finish crossing. Completing the route earns laps. Reversing subtracts progress; sudden discontinuous jumps are rejected. Recovery rebases the sampler without adding travel.

There are no narrow checkpoint gates. Leaving the road gradually lowers the speed limit through two cuts. Three completed circuits finish the race.

## Scenery

Snowy art remains in `AlpineTrack.gd`. `BiomeDecor.gd` builds jungle and candy scenery. `CityDecor.gd` supplies buildings, batched windows, lamps, crossings and a clock tower. `TrackLife.gd` adds animated polar bears, arctic foxes, lemurs, toucans, swaying lollipops, waving gingerbread spectators, moving buses and pigeons.

Shared geometry helpers in `scripts/art/AlpineArt.gd` use smoother rounded meshes and deterministic surface grain. All art is local and procedural.

The split-screen cameras share one World3D and one simulation. Avoid adding a second copy of the course to support another player.
