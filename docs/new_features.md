> Historical design proposal. For the playable November 2026 rebuild, see README.md and IMPLEMENTATION_SUMMARY.md. Feature claims below do not describe the current shipped milestone.

# New Features Implementation Guide

## Overview
This document describes the major improvements added to Dogsled Kart, transforming it from a simple racing prototype into a full-featured game with progression systems.

## Feature 1: Achievements System

### What It Does
Tracks player accomplishments across all races and sessions. Unlocking achievements provides a sense of progression and mastery.

### Key Components
- **AchievementManager.gd** — Global singleton (autoload)
- Eight initial achievements covering various gameplay milestones
- Persistent save/load system using `user://achievements.save`
- Signal-based notification system

### Available Achievements
1. **Musher Rookie** — Complete your first race
2. **Speed Demon** — Reach 100 km/h
3. **Perfect Line** — Complete a lap without hitting walls
4. **Alpine Champion** — Win on Alpine track
5. **Endurance Musher** — Complete 3 races in one session
6. **Lightning Run** — Complete a race in under 2 minutes
7. **Pure Skill** — Win without using powerups
8. **Item Collector** — Collect 50 items in total

### Integration Points
RaceManager calls achievement tracking functions:
- `on_race_completed()` — After finishing any race
- `on_speed_reached(speed)` — Continuously from SledController
- `on_perfect_lap()` — When lap completes with no wall hits
- `on_track_won(track_name)` — When player wins
- `on_fast_finish(time)` — When race finishes quickly
- `on_item_collected()` — When picking up items (future)

### Signals
- `achievement_unlocked(achievement_id)` — Fired when achievement unlocks
- `achievements_milestone_reached(count)` — Fired at 5, 10, 15, 20 achievements

### Adding New Achievements
Edit `AchievementManager.gd` `ACHIEVEMENTS` dictionary:
```gdscript
"new_achievement_id": {
    "name": "Achievement Name",
    "description": "What the player must do",
    "icon": "",  # Path to icon
    "unlocked": false
}
```

Then call `unlock_achievement("new_achievement_id")` at the appropriate time.

---

## Feature 2: Course Selection & Unlocking

### What It Does
Provides multiple race tracks with a progression system. Courses unlock as players earn achievements, motivating continued play.

### Key Components
- **CourseManager.gd** — Global singleton (autoload)
- Five courses with increasing difficulty
- Unlock system tied to achievement milestones
- Best time tracking per course

### Course Roster
1. **Alpine Valley** (Unlocked) — Starter course, gentle mountain pass
2. **Forest Rush** (5 achievements) — Dense forest with tight turns
3. **Frozen Canyon** (10 achievements) — Ice canyon with narrow paths
4. **Aurora Peaks** (15 achievements) — Mountain peaks with elevation changes
5. **Blizzard Bowl** (20 achievements) — Ultimate challenge, low visibility

### Course Unlock Logic
When player reaches achievement milestones (5, 10, 15, 20), `CourseManager` automatically unlocks corresponding courses. Connection happens via:
```gdscript
AchievementManager.achievements_milestone_reached.connect(_on_achievement_milestone)
```

### Course Data Structure
Each course has:
- `name` — Display name
- `description` — Brief description
- `scene_path` — Path to track scene file
- `difficulty` — 1-5 rating
- `locked` — Initial lock status
- `best_time` — Player's best completion time
- `thumbnail` — Preview image path
- `unlock_requirement` — Number of achievements needed

### Integration Points
- **MainMenu** — "Play" button loads selected course
- **CourseSelect** — UI for browsing and choosing courses
- **RaceManager** — Saves best time after race completion

---

## Feature 3: Course Selection Menu

### What It Does
Provides a visual interface for browsing all courses, seeing which are locked/unlocked, and selecting which track to race.

### Key Components
- **CourseSelect.tscn** — Scene file (needs creation in Godot editor)
- **CourseSelect.gd** — Script handling UI logic

### UI Layout
```
CourseSelect
├── MarginContainer
│   └── VBoxContainer
│       ├── ScrollContainer
│       │   └── CourseList (VBoxContainer)
│       │       └── [Course buttons generated dynamically]
│       ├── DetailsPanel (shows selected course info)
│       │   └── VBoxContainer
│       │       ├── CourseName (Label)
│       │       ├── Description (Label)
│       │       ├── Difficulty (Label - shows stars)
│       │       ├── BestTime (Label)
│       │       ├── UnlockRequirement (Label - if locked)
│       │       └── StartButton (Button)
│       └── BackButton (Button)
```

### User Flow
1. Player clicks "Course Select" from main menu
2. List shows all courses (locked ones grayed out with 🔒)
3. Player selects a course to see details
4. If unlocked, "Start" button loads that track
5. If locked, displays requirement ("Requires 10 achievements")
6. "Back" returns to main menu

### Customization Notes
This UI is functional but basic. You can enhance it by:
- Adding thumbnail images for each course
- Animated transitions between selections
- 3D preview of track layout
- Weather/time-of-day previews

---

## Feature 4: Achievements Screen

### What It Does
Shows all achievements, their unlock status, and player progress toward completion goals.

### Key Components
- **AchievementsScreen.tscn** — Scene file (needs creation in Godot editor)
- **AchievementsScreen.gd** — Script handling UI logic

### UI Layout
```
AchievementsScreen
├── MarginContainer
│   └── VBoxContainer
│       ├── ProgressBar
│       │   └── ProgressLabel (shows "X / Y unlocked")
│       ├── ScrollContainer
│       │   └── AchievementsList (VBoxContainer)
│       │       └── [Achievement items generated dynamically]
│       └── BackButton
```

### Visual Indicators
- **Unlocked**: Full color, 🏆 icon, achievement name and description visible
- **Locked**: Grayed out (50% opacity), ⬜ icon, shows what's needed

---

## Feature 5: Updated Track Design Philosophy

### What Changed
- **Removed visible checkpoint gates** — Cleaner racing experience
- **Invisible trigger zones** — Checkpoints are Area3D nodes with no visual mesh
- **Emphasis on environmental detail** — Trees, rocks, buildings, atmospheric effects
- **Natural navigation** — Track layout guides player, not artificial markers

### Why This Improves Gameplay
1. **Immersion** — Feels like racing through real environments, not a gamey track
2. **Visual clarity** — No visual clutter on racing line
3. **Artistic freedom** — Scenery can be placed without worrying about gate placement
4. **Realism** — Dogsled racing in nature doesn't have gates!

### Implementation Notes
See [track_building.md](track_building.md) for detailed guide on creating detailed tracks.

---

## Feature 6: Dog Sled Visual Theme

### What Changed
Vehicle model concept changed from generic sled to **cartoon dogs pulling sleds**.

### Visual Concept
- Team of 3-5 cartoon dogs in harness
- Lead dog + team dogs + sled chassis
- Whimsical, family-friendly art style
- Optional customization (fur colors, accessories)

### Current Status
**Placeholder geometry only** — Using primitive capsules and boxes in `Sled.tscn`.

### Next Steps
1. Commission or create 3D character models (dogs + sled)
2. Place models in `godot/assets/vehicles/dog_sled/models/`
3. Create textures for variety
4. Animate dogs (run cycle, turns, idle)
5. Replace placeholders in `Sled.tscn`

See [dog_sled_assets.md](dog_sled_assets.md) for complete asset specifications.

---

## Feature 7: Main Menu Updates

### What Changed
Main menu now has four buttons instead of two:
1. **Play** — Starts race on currently selected course
2. **Course Select** — Opens course selection screen
3. **Achievements** — Opens achievements screen
4. **Quit** — Exits game

### Integration
`MainMenu.gd` now references `CourseManager` to load the selected course scene.

---

## Setup Instructions

### Godot Autoload Configuration
These new singleton scripts must be added to Project Settings → Autoload:

1. **AchievementManager**: `res://scripts/core/AchievementManager.gd`
2. **CourseManager**: `res://scripts/core/CourseManager.gd`

### Scene Creation Required
You'll need to create these scene files in Godot editor:

1. **CourseSelect.tscn** in `scenes/ui/` — Attach `CourseSelect.gd`
2. **AchievementsScreen.tscn** in `scenes/ui/` — Attach `AchievementsScreen.gd`

Scene structure is documented in Feature 3 and 4 sections above.

### Main Menu Scene Update
Update `MainMenu.tscn` to add two new buttons:
- "Course Select" button → calls `_on_course_select_pressed()`
- "Achievements" button → calls `_on_achievements_pressed()`

---

## Testing Checklist

- [ ] Run game, verify AchievementManager and CourseManager load without errors
- [ ] Complete a race, check that "Musher Rookie" achievement unlocks
- [ ] Reach 100+ km/h, check "Speed Demon" unlocks
- [ ] Open Achievements screen, verify achievements display correctly
- [ ] Open Course Select, verify Alpine Valley is unlocked, others locked
- [ ] Use console to unlock achievements: `AchievementManager.unlock_achievement("first_race")`
- [ ] Unlock 5 achievements, verify "Forest Rush" unlocks
- [ ] Select a course, press Start, verify correct track loads
- [ ] Complete race, verify best time saves and persists across sessions
- [ ] Create additional track scenes (Forest Rush, etc.) using updated guidelines

---

## Customization Guide

### Adding More Achievements
Edit `AchievementManager.gd`, add to `ACHIEVEMENTS` dictionary, create unlock trigger.

### Adding More Courses
Edit `CourseManager.gd`, add to `COURSES` dictionary, create track scene file.

### Changing Unlock Requirements
Modify `unlock_requirement` values in `CourseManager.gd` `COURSES` dictionary.

### Custom Main Menu Design
Replace `MainMenu.tscn` with your custom design. Keep the same button callbacks or update `MainMenu.gd` accordingly.

### Custom UI Theme
Apply a Godot Theme resource to all UI scenes for consistent styling:
- Create a `.tres` theme file
- Set fonts, colors, button styles
- Apply to root Control node in each UI scene

---

## Future Enhancements

### Achievements
- Achievement notification popup in-game
- Steam integration for Steam achievements
- Stat tracking (total distance traveled, total races, etc.)

### Courses
- More courses (10+ total)
- Dynamic weather variants of existing courses
- User-created course editor
- Time trial ghosts

### Visual
- Full 3D dog character models with animations
- Particle effects (snow spray, wind trails)
- Skybox variations per course
- Dynamic lighting per course theme

### Progression
- XP and leveling system
- Unlockable dog breeds and sled styles
- Cosmetic customization shop
- Leaderboards per course

---

## File Reference

### New Files Created
```
godot/scripts/core/
├── AchievementManager.gd
└── CourseManager.gd

godot/scripts/ui/
├── CourseSelect.gd
└── AchievementsScreen.gd

docs/
├── dog_sled_assets.md
└── new_features.md (this file)

godot/assets/vehicles/dog_sled/
├── models/README.md
├── textures/README.md
└── animations/README.md
```

### Modified Files
```
godot/scripts/core/RaceManager.gd
godot/scripts/vehicle/SledController.gd
godot/scripts/ui/MainMenu.gd
docs/track_building.md
```

---

## Questions & Support

If you encounter issues:
1. Check console output for error messages
2. Verify autoloads are configured correctly
3. Ensure scene files reference correct script paths
4. Confirm save file permissions (`user://` directory writable)

Have fun building your dogsled racing game! 🐕‍🦺🛷
