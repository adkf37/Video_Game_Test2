param([Parameter(Mandatory=$true)][string]$GodotPath)
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
Push-Location $repoRoot
try {
    python tools/build_web.py --godot $GodotPath
    if ($LASTEXITCODE -ne 0) { throw 'Godot web export failed' }
    # Always target the game's project; do not change the user's active configuration.
    gcloud run deploy dogsled-kart --source build/cloudrun `
        --project=dogsled-kart-af-20261114 --region=us-central1 `
        --allow-unauthenticated `
        --service-account=dogsled-host@dogsled-kart-af-20261114.iam.gserviceaccount.com `
        --cpu=1 --memory=256Mi --min-instances=0 --max-instances=2 `
        --concurrency=80 --timeout=60 --cpu-throttling `
        --labels='app=dogsled-kart,environment=playtest' --quiet
    if ($LASTEXITCODE -ne 0) { throw 'Cloud Run deployment failed' }
} finally {
    Pop-Location
}
