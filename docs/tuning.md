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
| Whip range / knockback | 6 m / 11 m/s |
| Whip cooldown / hit immunity | 3.5 / 0.8 seconds |

Drive momentum and impact momentum are separate so steering cannot immediately erase a hit. Both sleds receive opposite impulses; separating contacts are ignored. Finished and inactive sleds do not block the pack. Breeds and sled styles are cosmetic.

The first cut is 6 m wide. Its speed limit smoothly decreases from 25 m/s at the road edge to the first-cut cap. Over the next 8 m, the second cut smoothly lowers the limit to the deep-terrain cap. Boost is disabled outside the road. The normal throttle controller also approaches this limit.

| Difficulty | Trail half-width | First-cut edge cap | Deep second-cut cap | NPC throttle | Attack interval |
|---|---:|---:|---:|---:|---:|
| Easy | 10 m | 20 m/s | 10 m/s | 0.76 | 11 s |
| Medium | 8 m | 18 m/s | 8 m/s | 0.86 | 7 s |
| Hard | 6.8 m | 16 m/s | 6.5 m/s | 0.95 | 4.5 s |

Rivals use speed-adjusted lookahead, corner braking, scored passing lanes, blocked-lane braking and straightaway boosts. Their throttle differs slightly within the pack. Recovery is reserved for prolonged stalls or departures and uses the nearest trail.

Run `tools/test_game.ps1` after changing handling. Automated completion proves traversability; human playtesting is still needed to tune feel and competitive balance.
