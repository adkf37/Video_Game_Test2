Dogsled Kart

Lightweight 3D dogsled racing game (local, Windows) with arcade handling and Mario Kart–style vibes.

1) Project Summary

Dogsled Kart is a stylized 3D racing game where the player pilots a dogsled on snowy tracks. Core loop: start → race laps → pick up powerups → finish. The design prioritizes tight handling, readable tracks, and fast iteration over realism.

Design Pillars

Arcade feel: responsive steering, forgiving collisions, fun boosts

Readable racecraft: clear corners, track boundaries, simple hazards

Fast iteration: minimal art requirements early; swap assets later

Single-player first: AI opponents optional in Phase 3+

2) Target Platform and Constraints

Platform: Windows (local)

Input: Keyboard + gamepad (XInput) if easy

Performance: stable 60 FPS on a typical laptop GPU (lightweight scenes)

Offline: no server dependencies

3) Engine + Language Recommendation (VS Code friendly)
Recommended: Godot 4.x + GDScript

Why:

Lightweight exports, great iteration speed

Built-in physics, scenes, editor

GDScript reads like Python, good for rapid prototyping

VS Code works well for script editing + Git workflow (Godot remains the scene editor)

Alternative:

Unity + C# if you strongly want an “industry standard” pipeline or plan to expand later, but it’s heavier and typically slower to iterate solo.

Decision rule: If you want “finishable, lightweight, fun quickly” → Godot.

4) Game Scope (What we’re building)
MVP (must ship)

One playable sled, one track, time trial or 1v3 AI (AI optional)

Arcade driving: accelerate, brake, steer, drift-lite (optional), boost pad

Lap system + checkpoints

HUD: speed, lap, timer, position (if AI exists)

Simple pause + restart

Stretch Features (after MVP)

Powerups (3–5): boost, snowball, oil slick, shield, magnet

3 tracks (snow forest, canyon, aurora night)

AI opponents with rubber-banding-lite

Local split-screen (harder; late milestone)

5) Core Systems
5.1 Vehicle (Dogsled) Controller

Arcade controller (not a true vehicle sim). Requirements:

Stable at speed

Predictable turning

Tunable parameters (accel, top speed, turn rate, friction, drift amount)

5.2 Camera

3rd-person chase camera with:

Smooth follow and rotation damping

Slight look-ahead based on velocity

Collision avoidance optional (later)

5.3 Track + Lap Logic

Track defined by a loop of checkpoints (3D trigger volumes)

Lap increments only when checkpoints are hit in order

5.4 Items / Powerups (Phase 2+)

Item boxes on track

Player holds one item

Items affect speed, control, or opponents

5.5 AI Racers (Phase 3+)

Follow spline/path with steering correction

Simple behavior: chase line, avoid walls, use items occasionally

Difficulty via speed + “mistake rate”

5.6 UI/UX

Main menu: Play / Track Select / Quit

HUD in-race

Results screen

5.7 Audio + Feel

Sled runners on snow (loop, pitch with speed)

Dog barks on boosts / collisions

UI click sounds

6) Repo Layout (agent-friendly)
dogsledui/
  README.md
  docs/
    vision.md
    controls.md
    tuning.md
    track_building.md
    task_packets/
  godot/
    project.godot
    scenes/
      main/
        Main.tscn
      vehicles/
        Sled.tscn
      tracks/
        Track_Alpine01.tscn
      ui/
        HUD.tscn
        MainMenu.tscn
      props/
        ItemBox.tscn
        Checkpoint.tscn
    scripts/
      core/
        GameState.gd
        RaceManager.gd
        Settings.gd
      vehicle/
        SledController.gd
        SledTuning.gd
      camera/
        ChaseCamera.gd
      track/
        Checkpoint.gd
        LapTracker.gd
      items/
        ItemSystem.gd
        ItemBox.gd
        items/
          BoostItem.gd
          SnowballItem.gd
      ai/
        AIRacer.gd
        PathFollower.gd
      ui/
        HUD.gd
        MainMenu.gd
    assets/
      placeholder/
        models/
        textures/
        audio/
  tools/
    export_windows.ps1
    lint.ps1
    format.ps1

7) Scene Graph (high level)

Main.tscn

GameState (autoload singleton)

RaceManager

Track (current track scene instance)

PlayerSled

AIOpponents (optional)

ChaseCamera

HUD

8) Key Files + Responsibilities
scripts/core/GameState.gd

Global state: menu/racing/paused/results

Track selection, settings

scripts/core/RaceManager.gd

Countdown

Start/finish triggers

Lap + timer

Positions (if AI)

scripts/vehicle/SledController.gd

Reads input

Applies movement forces / velocity changes

Handles collisions (soft wall bounce)

Calls item usage, boost effects

scripts/camera/ChaseCamera.gd

Smooth follow target

Adjusts distance/height based on speed

Optional camera shake on impact

scripts/track/LapTracker.gd

Checkpoint ordering validation

Lap increment, finish conditions

scripts/items/ItemSystem.gd

Item pick-up, hold, use

Spawns item effects

scripts/ai/AIRacer.gd (Phase 3)

Follows path, throttle logic, rubber banding

9) Tuning Parameters (centralize them)

Create a single tuning file so agents don’t scatter constants:

SledTuning.gd contains:

accel, max_speed, turn_rate, brake, lateral_friction

boost_strength, boost_duration

wall_bounce, offroad_slowdown

Track tuning:

checkpoint count

lap count

offroad zones friction modifier

10) Roadmap (MVP → Fun → Content)
Phase 0 — Repo & Scaffolding (1–2 sessions)

Godot project created, folder structure in place

Main menu loads Main scene

Placeholder sled can move on a flat plane

Exit criteria: press Play → drive around → ESC pause → restart.

Phase 1 — Core Racing MVP

Chase camera

Track boundaries + checkpoints + lap counting

Timer + minimal HUD

One track loop (simple oval with 6–10 checkpoints)

Exit criteria: complete 3 laps, show finish time, restart works.

Phase 2 — “Fun Layer”

Boost pads

3 powerups (Boost, Snowball, Shield)

Basic hit reactions (slow, spin-out lite)

Sound effects

Exit criteria: powerups meaningfully affect a lap; no crashes after 10 minutes.

Phase 3 — AI Opponents (optional but very “kart”)

3 AI racers follow path

Simple catch-up mechanic

Position tracking

Exit criteria: race feels competitive; player can win/lose.

Phase 4 — Content & Polish

2 more tracks

Better models + particles (snow spray)

Menu polish, settings, controller remap (optional)

11) Agent Workflow (how AI agents should operate)
Roles

Lieutenant (Planner): breaks work into task packets, enforces acceptance tests, keeps docs updated.

Executor (Coder): edits code/scenes for a single packet, runs game, fixes errors.

Reviewer (QA): checks for regressions, style consistency, playability.

Task Packet Format (copy template)

Create one file per task in docs/task_packets/NN_feature_name.md.

Task Packet

Goal: (one sentence)

Files: (exact file list to touch)

Implementation notes: (2–6 bullets)

Acceptance tests: (exact steps + expected result)

Non-goals: (what not to do)

Done when: (checkbox list)

Example Acceptance Tests should be concrete:

“From Main Menu → Play: sled moves with WASD; speed shows on HUD; lap increments only after all checkpoints.”

Rules for Agents (important)

Prefer small PR-sized changes (one packet at a time)

Never change tuning constants outside SledTuning.gd without updating docs

Any new system must include:

minimal debug UI or print statements behind a toggle

a short note added to docs/vision.md or docs/tuning.md

12) Verification Checklist (Definition of Done for MVP)

 Game launches from editor, no errors in console

 Player can complete a lap; timer works; finish screen appears

 No “stuck in wall” issues for 10 minutes of driving

 Sled tuning parameters are centralized

 Repo has a one-page docs/controls.md and docs/track_building.md

 Windows export builds and runs on a second machine/user profile

13) Minimal “First Track” Spec (Alpine01)

Width: forgiving (player can recover)

2 long straights, 4 corners

1 shortcut behind a snowbank (later)

Offroad snow slows by 25–40%

8 checkpoints placed after corners + mid-straights

14) Initial Control Scheme

W/S accelerate/brake

A/D steer

Space item use / boost

Shift drift-lite (optional)

Esc pause