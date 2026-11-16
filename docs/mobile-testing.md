# Mobile browser playtest

URL: https://dogsledkart.cloud.run/mobile

Mobile offers all four tracks, all three difficulties, all four dog breeds and all four sleds, with solo racing against three NPCs. Shared-keyboard split-screen remains available on the desktop page. The common game export enables phone input with `?mobile=1`; validated `course`, `difficulty`, `breed` and `sled_style` query values select the race. Phone records use `user://dogsled_mobile_test_v1.cfg`, separate from desktop saves. The HTML garage remembers choices in localStorage, with a fallback when storage is unavailable.

## Playing

- Hold the phone sideways, choose your race, load it and tap Start. This tap also unlocks audio.
- Hold the arrows to steer. Acceleration is automatic. Hold Boost for speed, Drift through turns, or Brake to slow and then reverse. Tap Bone when carrying one near an opponent.
- Pause offers camera, recovery (+3 seconds), volume, mute and exit.
- Going upright or leaving the page pauses the race. Resume is explicit. Returning to basecamp unloads the game.
- Tilt is disabled: there are no motion listeners or permission requests. The old steering math module remains unused for possible future work.

## Implementation

`web/mobile/` contains the responsive garage and independent touch pointers, so steering and actions work together. The optional screen wake lock never blocks racing.

`web/mobile-engine.js` is inserted before Godot starts. It captures audio contexts for unlocking from a user tap and forwards startup failures. The parent and child validate message source and origin. `MobileBridge.gd` owns game commands and publishes compact race state at 10 Hz. Controls expire after 0.7 seconds without input; a 1.5-second connection loss pauses the game. Touch cancel, focus loss and pause release held controls.

Phone rendering uses CSS-pixel resolution inside the game iframe, no MSAA/shadows and half the background trees. HTML controls retain the display's full pixel density. The gameplay, opponents and hazards remain shared. The initial download still includes the common game assets; there is no separate native app or multiplayer networking.

## Verification

From the repository root:

```powershell
& $GodotPath --headless --path godot --fixed-fps 60 --script res://tests/mobile_test.gd
& $GodotPath --headless --path godot --fixed-fps 60 --script res://tests/mobile_drive.gd
```

The native tests cover mobile commands, automatic acceleration, one-shot throws, pause/resume, stale controls, recovery, camera, audio toggle, complete results and replay. The driving bot completes three laps using only mobile steering commands with items and hazards active.

After `tools/build_web.py`, run `node preview-server.mjs` from `web/`, then `node test-mobile.mjs` in another terminal there. `GAME_TEST_URL` selects the public site; `GAME_TEST_ARTIFACT_DIR` selects screenshots. The browser test covers portrait/landscape, disabled motion permissions, real engine startup, simultaneous touches in Chrome, cancellation, all track/difficulty/garage choices, remembered settings and volume, rotation, pause, sound, camera and exit. Chrome also meters actual audio after the Start tap. `GAME_TEST_BROWSER=webkit` runs the WebKit variant; Windows Playwright WebKit uses a dummy audio driver, so that run cannot certify audio.

Physical iPhone/Android performance and sustained frame rate still need device testing across the expanded tracks. Try both landscape directions, interrupted touches, switching apps and returning, headphones/speakers, and a full race on each target phone. The user has reported that arrow controls work well on their phone.

The Windows WebKit run completes the interaction assertions but reports `glBlitFramebuffer` graphics errors and lacks a working audio driver. Its overall check therefore remains failing; it is not an iPhone compatibility certification. Chrome mobile emulation passes without browser errors, including audio. A real Safari/iPhone test is needed to determine whether the WebKit graphics issue is specific to the Windows test port.
