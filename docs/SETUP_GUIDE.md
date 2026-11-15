# Setup

1. Open `godot/project.godot` in Godot 4.6.3 and press F5.
2. Choose solo or local two-player mode, a track and a difficulty.
3. Choose each player's dogs and sled, then start the race.
4. Player 1 uses WASD, F boost, Shift drift, E throw bone, R recovery and C camera. Player 2 uses arrows, slash boost, period drift, comma throw bone, Backspace recovery and Enter camera. Esc pauses both.

Alternatively, run `tools/run_game.ps1`, supplying `-GodotPath` if Godot is not found automatically.

No manual scene or autoload setup is needed. The autoload is `GameState`; the main scene is `scenes/main/Main.tscn`. Compatibility rendering is enabled. All art is generated locally.

See the root README for validation and save behavior, and [controls](controls.md) for the full layout.
