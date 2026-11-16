# Browser playtest on Cloud Run

Play: https://dogsledkart.cloud.run

Original service URL (still works): https://dogsled-kart-439446327091.us-central1.run.app

Manage: https://console.cloud.google.com/run/detail/us-central1/dogsled-kart/metrics?project=dogsled-kart-af-20261114

The Godot game runs on the player's computer using WebAssembly and WebGL 2. Cloud Run serves the launch page and exported files; it does not render the game or host multiplayer matches. Two-player mode shares one keyboard.

## Hosting configuration

- Google Cloud project: `dogsled-kart-af-20261114` (Dogsled Kart).
- Cloud Run service: `dogsled-kart`, region `us-central1`.
- Public HTTPS access, with no login. Search indexing is discouraged by page metadata.
- Request-based billing, 1 CPU, 256 MiB RAM, zero minimum instances, two maximum instances, concurrency 80.
- Dedicated runtime identity: `dogsled-host`, without application-specific cloud permissions.
- Container built remotely with Cloud Build and stored in the project's `cloud-run-source-deploy` Artifact Registry repository.
- Existing billing account pays for this separate project. Instance limits are not a spending cap; outbound downloads, build storage and container storage can also incur charges.

The custom URL `dogsledkart.cloud.run` maps directly to this service using Cloud Run's custom URL preview. No domain registration, DNS zone, external load balancer, or online game server is configured. The first request after idle may take longer while Cloud Run starts a container. The user's active gcloud project configuration is not changed.

## Custom URL

The mapping belongs to the game project and survives service revisions. Updating the game does not require recreating it. Avoid deleting the mapping: deletion releases the name for others to claim. Cloud Run custom URLs are currently a preview feature: https://docs.cloud.google.com/run/docs/custom-urls

Inspect the existing mapping:

```powershell
gcloud beta run domain-mappings describe --domain=dogsledkart.cloud.run --project=dogsled-kart-af-20261114 --region=us-central1
```

The installed gcloud 568 client predates support for claiming `.cloud.run` names and incorrectly requests domain ownership verification when creating one. The mapping was created with the documented Cloud Run DomainMapping REST API using the existing gcloud account. A current gcloud release supports creation with `gcloud beta run domain-mappings create --service=dogsled-kart --domain=dogsledkart.cloud.run --project=dogsled-kart-af-20261114 --region=us-central1`.

Saves on the original `run.app` address stay there; the new address has its own browser storage.

## Export and deploy an update

Use Godot 4.6.3 with its matching Web export templates. If templates are missing, `python tools/fetch_web_templates.py` installs the single-threaded release and debug templates from the official release archive using range requests.

From the repository root:

```powershell
.\tools\deploy_web.ps1 -GodotPath 'C:\path\to\Godot_console.exe'
```

The script creates `build/cloudrun/` from current working-tree files, exports the game, precompresses assets, and deploys that directory. It requires Python and authenticated gcloud credentials with access to the game project. Docker does not need to run locally. Only generated web files and the nginx container configuration are uploaded; credentials and the rest of the workspace are excluded by staging.

The launch page fetches `build.json`, then waits for Play before requesting the game. Each export has a unique asset directory. Long-lived immutable caching is safe inside that directory. nginx serves precompressed `.gz` siblings, including WebAssembly. The initial compressed game payload is approximately 9.2 MiB; the landing-page preview is separate. Actual load time depends on the connection, device, and shader compilation.

Single-threaded export avoids requiring cross-origin isolation headers. No installation is needed. Test on a desktop with a keyboard and a WebGL 2-capable browser. Touch controls are not implemented. Garage preferences and records use browser-local storage; clearing site data removes them. Different domains and browsers have separate saves.

## Browser checks

Export locally without deploying:

```powershell
python tools/build_web.py --godot 'C:\path\to\Godot_console.exe'
cd web
npm ci
node preview-server.mjs
```

In another terminal, run `npm test` from `web/`. Tests use installed Google Chrome via Playwright. They check lazy loading, controls, startup, solo and two-player keyboard interaction, leaving the game, mobile landing-page layout, and browser errors. Inspect the screenshots in `artifacts/web-*.png` to verify the rendered game state.

To check the live service:

```powershell
$env:GAME_TEST_URL = 'https://dogsledkart.cloud.run'
cd web
npm test
```

`/health` returns `ok`. `/build.json` identifies the deployed export. Verify the `.wasm` response has `Content-Type: application/wasm` and `Content-Encoding: gzip` when requested with gzip support.

The browser smoke test is not a cross-browser or low-end-device performance certification. The native physics/regression suites remain available through `tools/test_game.ps1`.

Verified on the public service on November 14, 2026 (Eastern): Chrome loaded the game in approximately 5.2 seconds on the development machine's connection. Solo driving, pause, musher view and City Sprint split-screen with both players driving were exercised and visually checked. There were no browser console errors. The live `/health`, cache headers and gzip WebAssembly MIME type passed checks. Revision: `dogsled-kart-00002-mvx`; exported game: `20261115-034909-c7e63a2`. Performance on other devices and connections remains to be tested.


November 15 update: Golden Bones, revised dog models, solo controls and animated track spectators deployed as `dogsled-kart-00003-9x6`, build `20261115-161843-649ffc9`. The initial source upload timed out; a separate Cloud Build retry succeeded, then that image was deployed. Public build metadata, health and Golden Bone controls were verified. Chrome passed solo/musher-view and City Sprint split-screen checks with no browser errors; game startup on this connection was approximately six seconds. Fresh screenshots are in ignored `build/live-qa/`. Set `GAME_TEST_ARTIFACT_DIR` to change the browser test output directory if an existing screenshot is locked.

November 15 hazards/music update: revision `dogsled-kart-00004-lgl`, build `20261115-200138-649ffc9`, 100% traffic. Cloud Build `8426001e-230f-4a81-86ae-434f3ea58315` succeeded; image tag `hazards-music-20261115-200138`. Public build metadata and `/health` verified. Live Chrome checks passed solo/duel driving, camera, pause and actual Web Audio music/mute/resume with no console errors. Startup measured 6.26 seconds on this connection; compressed export is 10.1 MiB. Current screenshots/logs are in ignored `build/hazards-live-qa/`. The new audio test meters Web Audio output rather than relying only on asset requests.

November 16 mobile test deployment: `/mobile` and `/mobile/` serve the phone playtest alongside the desktop page. Revision `dogsled-kart-00007-qc4` serves 100% of traffic, exported build `20261116-041733-9c960ba` (12.6 MiB). Cloud Build `3f28cc00-53fa-4061-a6c3-ed59be12c6ef` succeeded; image digest `sha256:ed0db7b33240af263069882bad0b69b175d6afd0a74f5f20326a39269dbf69e3`. The original source upload stalled; uploading the archive through `gcloud storage cp` and submitting that archive succeeded. Deployment resumed after a session interruption.

Public build metadata, both mobile paths, desktop `/` and `/health` were verified. Live Chrome mobile emulation passes startup, real audio output, denied/missing sensors, synthetic tilt/calibration, touch steering and simultaneous boost, cancellation, pause, camera, mute, orientation changes and exit. Screenshots are in ignored `build/mobile-live-qa/`. Physical phones remain untested, and the Windows WebKit run reports graphics errors; see `docs/mobile-testing.md` for the verification limits.

November 15 audio update: revision `dogsled-kart-00005-kwr` (deployed 21:27 UTC), build `20261115-212636-8e14037`, 100% traffic on both `dogsledkart.cloud.run` and the original run.app URL. Verified afterwards: `build.json` matches, `/health` is ok, the served `index.pck` contains the new dog, ambience, drum-stem, runner and menu sounds, and `npm test` against the public URL passed launch, controls, solo/duel input, mobile layout and Web Audio playback/mute/resume with no browser errors. Download is 12.3 MiB (the audio grew by about 2.5 MB); startup measured 5.9 seconds.

November 15 mix update: revision `dogsled-kart-00006-jz8`, build `20261116-035740-6347cf4`, serving 100% of traffic. Both public URLs returned the new build and healthy status; gzip WebAssembly headers passed. Live browser checks passed launch, solo/duel input, mobile layout and audio playback/mute/resume without browser errors. Startup measured 6.5 seconds and the compressed game download is 12.5 MiB.


November 16 expanded mobile update: revision `dogsled-kart-00008-w79` serves 100% of traffic. Build `20261116-134633-9c960ba`, 12.6 MiB, image digest `sha256:268493226aa92a697c2663848145c9a8179d2143dc2f68cf4b7e3c8279d6ad98`, successful Cloud Build `69efbe2d-d0dd-4a60-8171-8e2887d2335d`. Mobile now has all solo tracks/difficulties/garage options, touch-only steering, brake/reverse, drift, camera, recovery, volume and mute. Both landing pages use the supplied navy/blue/mint palette. Golden Bone collection radius is 1.9375m (25% larger); each race shuffles NPC pace and changes the favorite on a rematch. The complete native suite and local desktop/mobile Chrome checks passed. Public health, build metadata and both mobile paths return the new version.

The first source archive upload failed its checksum; a retry was accepted by the CLI but failed Cloud Build's gzip CRC check (build `27feb8d6-5a81-4da8-b4fd-e5644fc7d24c`). Local decompression succeeded and comparison of the downloaded object showed three altered bytes. Uploading with an explicit `--content-md5` and verifying the object's `md5_hash` against the local file succeeded. Preserve checksum verification for future uploads.

Post-deploy Chrome checks passed on https://dogsledkart.cloud.run: all four mobile tracks and garage choices, no motion prompts, remembered settings, simultaneous touch steering/boost, audio, volume, pause/resume, camera, rotation and exit; desktop solo/duel controls and audio also passed without browser errors. Screenshots: ignored `build/mobile-expanded-live-qa/` and `build/desktop-expanded-live-qa/`. Physical-phone performance across the new courses remains unverified.


November 16 obstacle/turbo update: revision `dogsled-kart-00009-fwl`, build `20261116-151618-9c960ba` (12.6 MiB), serving 100% of traffic. Successful Cloud Build `1cec4b44-e06a-411e-b627-54d8ed262fb9`; image digest `sha256:abd127adac10919b13178033ee448ee1ef4c710ca2f93944cac228871efb2df8`. The uploaded archive was verified with an explicit MD5 and matching Storage object checksum. Public build metadata and health passed; the public PCK SHA-256 matches the tested local export.

Reproduced an invisible ground-triangle wall at Alpine progress 0.608333, lane +10.6m on Easy. The sled now completes its intended horizontal movement across these ground seams while still testing collision against other racers. All 81 forward passages through Alpine flags/signs (27 per difficulty) pass. Theme hazards stop a team for one second and no longer separate/push it backward; a continuous overlap cannot retrigger even after immunity expires. Golden Bone chase is also one second. Desktop solo/split-screen turbo meters show percentage remaining, a proportionate larger bar, low-energy amber and use/refill instructions; the phone turbo button also shows percent remaining.

Validation: item 23 checks, hazard 58 checks, marker passage 81 runs, existing smoke/contact/duel/scenery/audio/results/mobile tests, and complete solo/NPC/duel races on all four tracks passed. Chrome desktop/mobile tests passed locally, including visual review of full/active/low turbo and split-screen layout. An old NPC item-test assertion still expected a two-second chase and was updated to the one-second rule. Screenshots are in ignored `build/obstacle-turbo-desktop-final-qa/` and `build/obstacle-turbo-mobile-qa/`.

Post-deploy desktop and mobile Chrome checks passed on the public URL without browser errors, including real audio output, solo/duel input, turbo display, mobile garage selections, touch controls and pause/resume. Live screenshots: `build/obstacle-turbo-live-desktop-qa/` and `build/obstacle-turbo-live-mobile-qa/`.
