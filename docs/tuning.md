# Sled tuning

Movement and contact constants live in `godot/scripts/vehicle/SledTuning.gd`. Garage and difficulty values live in `scripts/core/RaceCatalog.gd`.

| Setting | Value |
|---|---:|
| Acceleration | 12 m/s squared |
| Normal / boost speed | 25 / 36 m/s |
| Reverse speed | 6 m/s |
| Brake force / coasting drag | 24 / 3 m/s squared |
| Turn rate | 1.25 rad/s |
| Normal / drift grip | 7 / 1.8 per second |
| Drift turn multiplier | 1.3 |
| First / second cut additional deceleration | 8 / 32 m/s squared |
| Boost drain / recharge | 38 / 13 per second |
| Recovery penalty | 3 seconds |
| Bounce restitution | 0.6 |
| Pair collision cooldown | 0.3 seconds |
| Maximum bump impulse | 45 m/s |
| Impact decay | 20 m/s squared |
| Bone targeting range / flight | 26 m / 0.55 seconds |
| Bone chase / protection after chase | 2 / 4 seconds |
| Pickup respawn / inventory capacity | 10 seconds / 1 bone |
| Pickups per track / collection radius | 3 / 1.55 m |
| Coconut stun / hazard immunity | 1.5 / 3 seconds |

Drive momentum and impact momentum are separate so steering cannot immediately erase a hit. Both sleds receive opposite impulses; separating contacts are ignored. Finished and inactive sleds do not block the pack. Breeds and sled styles are cosmetic.

The first cut is 6 m wide. Its speed limit smoothly decreases from 25 m/s at the road edge to the first-cut cap. Over the next 8 m, the second cut smoothly lowers the limit to the deep-terrain cap. Boost is disabled outside the road. The normal throttle controller also approaches this limit.

| Difficulty | Trail half-width | First-cut edge cap | Deep second-cut cap | NPC throttle | Minimum NPC throw interval |
|---|---:|---:|---:|---:|---:|
| Easy | 10 m | 20 m/s | 10 m/s | 0.95 | 8.8 s |
| Medium | 8 m | 18 m/s | 8 m/s | 1.075 | 5.6 s |
| Hard | 6.8 m | 16 m/s | 6.5 m/s | 1.1875 | 3.6 s |

NPC target pace is multiplied by 1.25, including pack variation; this is a tuning change, not a claim that win probability changes by exactly 25%. Boost and item cooldowns divide by 1.25. Rivals use speed-adjusted lookahead, corner braking, scored passing lanes (including hazard avoidance), blocked-lane braking and straightaway boosts. Recovery is reserved for prolonged stalls or departures and uses the nearest trail.

Run `tools/test_game.ps1` after changing handling. Automated completion proves traversability; human playtesting is still needed to tune feel and competitive balance.

Golden Bone tuning lives in `scripts/core/RaceItems.gd`. Players and rivals use the same pickups; the NPC throw interval only applies when carrying an item and an eligible target is nearby.

`TrackHazards.gd` owns three themed hazard stations, plus two Alpine snowballs. Crossings warn for 2 seconds and traverse for 6; cycles last 17/15.5/14 seconds by difficulty. Lollipops warn, fall for 1 second, remain down for 4 and rise for 1; their footprint stays on one side and covers 48% of road width. Coconuts mark a fixed landing point for 0.65 seconds before a 0.95-second visible arc; racers can dodge the 2 m landing radius. Stuns and movement freeze on pause; recovery/restart clear effects. Swept contacts and separation prevent driving through obstacles while protected from repeat penalties.

Score, ambience and effects are built by `tools/build_audio.py` (44.1 kHz) into checked-in Ogg files; CC0 sources are in `tools/audio_sources/` and credited in `godot/assets/audio/CREDITS.md`. The script checks that decoded peaks stay under -1 dBFS and that music loudness is sane. Each course has a melody stem and a drum stem played through `AudioStreamSynchronized`; `RaceAudio.gd` fades the drum stem in with speed (0.7 to 1.0 while racing, 0.2 in menus) and pins it at full on the final lap. Event sounds use `AudioStreamRandomizer` variants. Sled runner, drift, off-track and panting loops follow speed (levels are the `lerpf` dB ranges in `_update_foley`). Rivals use `AudioStreamPlayer3D` loops with a manual Doppler shift. Everything shares one limiting bus (`RaceMix`), with per-player pan buses only in duels, and a single master volume (`GameState.volume`, default 0.7 = 0 dB) on the Master bus. Solo rival estimates use distance traveled / elapsed time, with a nominal pace fallback if a rival has barely started; estimates preserve on-track order and never overwrite actual finish times.
