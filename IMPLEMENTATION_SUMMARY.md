# Local two-player and scenery update

Added top/bottom split-screen with two independent human teams and two NPCs. Inputs use opposite sides of the keyboard, with no Space-bar racing action. Player 1 boosts with F and changes view with C; Player 2 uses slash for boost and Enter for camera. Each player owns their controls, garage choices, lap tracking, clock, recovery penalties and camera. Results wait for both humans; local duels do not write solo records.

Added musher POV with camera-specific visibility so a player's head does not block their view. The throne driver now stands on a front platform. City Sprint joins the other three courses, and every course has more rolling elevation. A six-metre first cut slows gently; a second eight-metre cut progressively slows more.

Smoother rounded meshes and surface grain add detail. New roadside elements include animated polar bears and lemurs, spiral lollipops, city buses, windows, lamps and a clock tower. Shared split-screen rendering uses one world and one simulation. Removing unused sky cubemaps also cleared the preview renderer's texture-leak errors on exit.

Validation in Godot 4.6.3: 31 smoke checks, 15 contact/whip checks and 22 local-duel checks passed. Steering bots finished all three laps in both solo and two-player modes on all four courses. All three NPCs finished each of the twelve course/difficulty combinations without recovery (36 finishes). Rendered previews cover all environments, roadside landmarks, musher view, the two-player garage and split-screen. Tests use practice mode or disposable saves.

The following entries describe earlier milestones; their track counts, controls and off-track rules are superseded above.

---

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


## Golden Bone and breed update (November 15, 2026)

- Replaced whipping with shared Golden Bone pickups: one held item, visible throw, nearest eligible opponent within 26 m, two-second off-track chase and four additional seconds of protection. Pickups respawn after ten seconds. NPCs use the same inventory and targets; stuck recovery waits during a chase.
- Added breed-specific models, including apple-headed Chihuahuas with large upright ears, short muzzles and fine legs. Reused sphere meshes to reduce geometry allocation.
- Added a prominent solo-controls panel at basecamp; duel instructions remain specific to each player. E / comma now throws a collected bone.
- Added arctic foxes, toucans, gingerbread spectators and pigeons. Existing bears, lemurs, lollipops and buses also animate.
- Validation: 31 race-state/save checks, 6 physical-contact checks, 22 duel checks, 22 item checks; animation checks on all four biomes; solo course completion and full two-player races on all courses; NPC completion on all twelve course/difficulty combinations. Road-only traversability checks isolate item interference; full duels and NPC races leave items enabled. Chrome browser smoke checks passed for solo, musher view, split-screen and the launch page.
- Records use `tour_v4` for the new item rules, preserving older saved records. Browser build remains approximately 9.2 MiB compressed.

## Hazards, music and challenge update (November 15, 2026)

- Reduced 21 bone pickups to three staggered single pickups (14.3%, nearest whole count to 15%); collection radius reduced from 2.4 to 1.55 m.
- Replaced runner noise and basic beeps with four original 16-bar melodic scores and eleven distinct effects. Checked-in stereo Ogg assets total under 1 MB. Music runs through menus/racing, ducks under events and shares a limiter with pooled effects; both players get cues. Generator: `tools/build_audio.py`.
- Increased NPC target pace 25% at every difficulty, with proportionally shorter boost/throw cooldowns. Added obstacle-aware lane selection. Records use `tour_v5`, preserving earlier times.
- Solo finish immediately resolves remaining NPCs in their current order, estimating times from average pace and remaining distance. Actual finishes remain intact; estimates are marked `est.`. Two-player finish behavior remains independent.
- Added three hazard stations per biome: wandering bears, coconut-throwing lemurs, falling lollipops and crossing buses. Alpine also gets two rolling snowballs. Visible warnings, fixed coconut landing rings, 1.5-second coconut stops, protection from repeat penalties, pause/restart cleanup and swept obstacle separation are covered by tests. Lollipops occupy 48% of the road width and leave the opposite side clear.
- Validation: 31 smoke, 6 contact, 22 duel, 23 item and 46 hazard checks; scenery checks; 24 solo-result checks across difficulties. Solo and two-player three-lap drives finish all four courses, as do all NPCs across twelve course/difficulty combinations. Final candy footprint changes were rechecked with hazard and NPC tests. Native hazard renders have no runtime errors. Chrome passes solo/duel, camera, pause and actual Web Audio playback/mute/resume checks without console errors. Export is 10.1 MiB compressed.

## Audio update (November 15, 2026)

- Rebuilt `tools/build_audio.py` at 44.1 kHz. Each course now has a melody stem and a synchronised drum stem; the drums fade in with speed and pin to full on the final lap. Added per-biome ambience beds (wind, jungle water and birds, candy chimes, city hum).
- Effects have variants played through `AudioStreamRandomizer` (4 crashes, 3 coconuts, 3 pickups, 3 throws, 2 boosts). Crashes and coconuts layer Kenney CC0 impacts with procedural bodies. Added final-lap and overtake stings.
- Added dog voices: six CC0 barks and a howl, pitched per breed, with chorus size by team count, plus a panting loop. Added quiet speed-reactive runner glide, drift scrape and off-track crunch loops for each human sled.
- Rivals now have positional runner loops (with a manual Doppler shift) and positional boost, bump, hazard and throw sounds. Two-player races pan each human's own sounds to their half of the stereo field. The listener follows the camera in solo and the midpoint of both sleds in duels.
- Added menu/pause sounds (Kenney Interface Sounds, CC0) on a persistent node, and one shared volume (-/+ in 10% steps, saved, default 0.7 = the previous mix level) on the Master bus. Sources and licenses: `godot/assets/audio/CREDITS.md`, raw files in `tools/audio_sources/`.
- Validation: new `audio_test` (54 checks) plus the full suite; a non-headless run with real playback confirmed every layer plays; a Godot movie-maker capture measured about -22 LUFS with a -6 dBFS peak. Audio assets grew from under 1 MB to about 3.5 MB. The browser export was not re-tested.
