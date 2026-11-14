# Setup

1. Open `godot/project.godot` in Godot 4.6.3.
2. Press F5.
3. Choose a track, difficulty, dog team and sled, then **Race the pack**.
4. Drive with WASD; Shift drifts, Space boosts, E whips, R recovers and Esc pauses.

Alternatively, run `tools/run_game.ps1`, supplying `-GodotPath` if Godot is not found automatically.

No manual scene or autoload setup is needed. The autoload is `GameState`; the main scene is `scenes/main/Main.tscn`. Compatibility rendering is enabled. All art is generated locally.

See the root README for the validation runner, controls and save behavior.
