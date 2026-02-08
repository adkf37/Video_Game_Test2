docs/task_packets/01_repo_scaffold.md

Task 01 — Repo Scaffold + Godot Project Skeleton

Goal: Create the Godot project structure, core scenes, and script folders so future tasks have stable paths.

Files:

godot/project.godot (created by Godot)

godot/scenes/main/Main.tscn

godot/scenes/ui/MainMenu.tscn

godot/scripts/core/GameState.gd

docs/vision.md

docs/controls.md

Implementation notes:

Use Godot 4.x.

Create folder structure exactly as in the Project Overview.

Set Main.tscn as the main scene in Project Settings.

GameState.gd should be an autoload singleton (Project Settings → Autoload).

MainMenu.tscn can be simple: title label + Play + Quit buttons.

Acceptance tests:

Run the project from Godot: it opens MainMenu.

Clicking Quit closes the game.

Clicking Play prints “TODO: start race” (temporary) and switches to Main.tscn or a placeholder “Race” scene.

Non-goals:

No driving, no track, no HUD yet.

Done when:

 Repo contains the folders and empty placeholder scenes

 GameState.gd autoload is working