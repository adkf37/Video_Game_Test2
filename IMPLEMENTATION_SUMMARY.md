# Three-course combat and garage update - November 14, 2026

Added physical sled bounces, sideways whip attacks (E / gamepad X), passing and attacking rivals, and Easy / Medium / Hard settings. Difficulty adjusts road width, off-track speed and rival pace/aggression.

The garage now offers four huskies, eight corgis, two mastiffs or twelve chihuahuas, with distinct proportions and animated layouts. Choose a wooden, carbon racing, chocolate or royal throne sled. Alpine Valley is joined by separate Jungle Rush and Candy Kingdom courses, each with procedural scenery.

Continuous signed route progress replaces missed checkpoint gates. Leaving the trail imposes a strong slowdown and disables boost; recovery uses the nearest trail point. Each course/difficulty combination has separate personal records, while legacy records are preserved.

Validation: 30 race smoke checks and 15 physical contact/whip checks passed. A steering bot completed three laps on every course; all three NPCs finished every course at all three difficulties without recovery (27 finishes). Rendered previews cover every breed and sled, all three environments and a whip impact. Live garage selections, race launch, pause/resume and the whip key were checked in the native window. Logical-key fallbacks also support virtual/accessibility keyboards; a simulated Escape event is covered by the smoke suite. Tests do not overwrite player records.

See the README for current behavior and controls. The following entries describe earlier milestones and are retained as history; their checkpoint and non-blocking collision descriptions are superseded above.

---

# NPC racing update - November 14, 2026

Added three named, color-coded rival dog teams using the shared sled physics. The game now opens a four-team race with live positions, a leaderboard, minimap opponents and a finish table. Each rival validates its own checkpoints and laps; finish order is locked as teams cross the line. Remaining rivals finish naturally after the player's results screen appears.

NPCs steer toward the course, slow for bends, boost on straights and choose passing offsets. Their only recovery returns to the last accepted checkpoint after a stall; there is no catch-up teleport or rubber-banding. Team collisions remain non-blocking.

The competition clock is separate from the player's recovery penalties. Pack-race records use a separate save section, preserving old solo records and the mute preference.

Validation includes the existing smoke suite plus `tests/npc_race.gd`: autonomous three-lap completion without recovery, winning and losing scenarios, pause/restart, isolated checkpoint state, start-line ranking and stable results. Preview screenshots now come from an actual four-team race.

---

# Alpine Valley rebuild

Updated November 13, 2026.

The workspace was missing all gameplay scripts and most scenes. The earlier prototype was recovered from Git commit `4300110` into the working tree, preserving the existing Git index, then rebuilt into a complete single-course time trial.

## Delivered

- A deterministic closed spline provides the road mesh, gentle elevation, snowy shoulders, sixteen invisible checkpoints, recoverable poses and a matching minimap.
- Original procedural art: four running huskies, tow lines, sled, musher, pines, cabins, lake, mountain silhouettes and a finish arch.
- Sled movement blends momentum toward the heading; drift reduces lateral grip, offroad snow slows the team, and boost consumes a rechargeable meter.
- A standing start behind the line, countdown, forward-only start validation, three full laps, ordered checkpoints, lap splits and finish lockout.
- Pause/resume, restart, basecamp, wrong-way/missed-marker guidance and recovery with a three-second penalty.
- Persistent race/lap records and mute preference in a versioned offline save.
- A complete UI, speed-responsive camera, snow spray and synthesized audio cues.
- Launch, test and preview scripts.

## Validation

Tested in the locally installed Godot 4.6.3 on Windows.

- Headless import and startup.
- Automated smoke suite including actual physical checkpoint entry and isolated save/reload tests.
- A steering-only bot completed all three laps through real physics and trigger volumes; maximum lateral displacement was 4.36 m on a trail with an 8 m half-width.
- Rendered menu, race, pause and results screens inspected at 1280x720.
- Native game window inspected; menu start confirmed using keyboard input.

The tests intentionally do not update the player's personal records. A physical gamepad and a standalone Windows export have not been tested.

## Scope and next pass

This is a playable foundation with simple procedural art. It is not a five-course game. Combat items, achievements, music and split-screen remain future work. NPC racing was added in the update above.

The next useful iteration is a human handling playtest: tune drift grip, turn response and boost duration from actual player feedback, then add authored terrain and richer dog animation.

## Git state

The rebuild commit reconciles the earlier staged deletions with the restored and updated working files. All playable scenes, scripts, tests, documentation and preview images are included; runtime logs and the Godot cache remain ignored.
