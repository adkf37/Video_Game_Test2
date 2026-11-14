# Setup

The current rebuild is ready to run. There are no manual scene or autoload setup steps.

1. Open `godot/project.godot` in Godot 4.6.3.
2. Press F5.
3. Choose **Race the pack**.
4. Drive with WASD; Shift drifts, Space boosts, Esc pauses.

Alternatively, run `tools/run_game.ps1` from PowerShell, supplying `-GodotPath` if Godot is not found automatically.

The only autoload is `GameState`. The main scene is `scenes/main/Main.tscn`. Compatibility rendering is enabled.

See the root README for tests and limitations. Earlier proposals for course and achievement managers are not active features of this milestone.

Three NPC teams join every race. No additional setup is needed.
