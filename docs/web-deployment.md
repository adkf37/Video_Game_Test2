# Browser playtest on Cloud Run

Play: https://dogsled-kart-439446327091.us-central1.run.app

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

No custom domain or online game server is configured. The first request after idle may take longer while Cloud Run starts a container. The user's active gcloud project configuration is not changed.

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
$env:GAME_TEST_URL = gcloud run services describe dogsled-kart --project=dogsled-kart-af-20261114 --region=us-central1 --format='value(status.url)'
cd web
npm test
```

`/health` returns `ok`. `/build.json` identifies the deployed export. Verify the `.wasm` response has `Content-Type: application/wasm` and `Content-Encoding: gzip` when requested with gzip support.

The browser smoke test is not a cross-browser or low-end-device performance certification. The native physics/regression suites remain available through `tools/test_game.ps1`.

Verified on the public service on November 14, 2026 (Eastern): Chrome loaded the game in approximately 5.2 seconds on the development machine's connection. Solo driving, pause, musher view and City Sprint split-screen with both players driving were exercised and visually checked. There were no browser console errors. The live `/health`, cache headers and gzip WebAssembly MIME type passed checks. Revision: `dogsled-kart-00002-mvx`; exported game: `20261115-034909-c7e63a2`. Performance on other devices and connections remains to be tested.
